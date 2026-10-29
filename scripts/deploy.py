#!/usr/bin/env python3
"""Deploy one image to the tldr app on Bunny Magic Containers and verify it.

The deploy workflow runs this after it pushed the image of a commit on main:

    python3 scripts/deploy.py --image-tag <full commit sha>

It needs an authenticated `bunny` CLI (BUNNYNET_API_KEY) and the key in
OPENROUTER_API_KEY. bunny.json names the app, the image and the plain
environment. SECRET_KEY_BASE lives only in Bunny and is kept as it is.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def api(method, path, body=None):
    # Responses hold the app's secrets. Never print a response or a CLI error.
    result = subprocess.run(
        ["bunny", "api", method, path],
        input=json.dumps(body) if body is not None else "",
        capture_output=True, text=True, timeout=60,
    )
    require(result.returncode == 0, f"Bunny API request failed: {method} {path}")
    return json.loads(result.stdout) if result.stdout.strip() else None


def the_container(app):
    require(app["name"] == "tldr", "Unexpected application.")
    require(len(app["containerTemplates"]) == 1, "Expected one container.")
    return app["containerTemplates"][0]


def runtime_environment(container, config):
    """Keep what Bunny holds, then lay bunny.json and the key over it."""
    environment = {item["name"]: item["value"] for item in container["environmentVariables"]}
    require(bool(environment.get("SECRET_KEY_BASE")), "Missing SECRET_KEY_BASE on the Bunny app.")
    require("SECRET_KEY_BASE" not in config["environment"], "SECRET_KEY_BASE belongs in Bunny, not bunny.json.")
    environment.update(config["environment"])
    environment["OPENROUTER_API_KEY"] = os.environ.get("OPENROUTER_API_KEY", "")
    require(bool(environment["OPENROUTER_API_KEY"]), "Missing OPENROUTER_API_KEY.")
    return [{"name": key, "value": value} for key, value in sorted(environment.items())]


def rolled_out(overview, digest):
    """True once every pod is ready and runs the new image."""
    pods = [pod for region in overview["regions"] for pod in region["pods"]]
    return overview["status"] == "active" and bool(pods) and all(
        pod["status"] == "ready" and all(
            c["status"] == "ready" and c.get("image", "").endswith("@" + digest)
            for c in pod["containers"]
        )
        for pod in pods
    )


def check_http(url):
    for path, expected in (("/healthz", b"ok"), ("/", b"data-phx-session")):
        request = urllib.request.Request(url + path, headers={"Cache-Control": "no-cache"})
        for attempt in range(1, 7):
            try:
                with urllib.request.urlopen(request, timeout=20) as response:
                    body = response.read()
                    ok = body == expected if path == "/healthz" else expected in body
                    require(response.status == 200 and ok, f"Unexpected answer: {url}{path}")
                break
            except (urllib.error.URLError, TimeoutError):
                # The CDN can lag a few seconds behind a ready pod.
                require(attempt < 6, f"No answer: {url}{path}")
                time.sleep(5)
    print(f"HTTP checks passed: {url}", flush=True)


def deploy(config, image_tag):
    require(bool(re.fullmatch(r"[0-9a-f]{40}", image_tag)), "Use a full commit SHA as the image tag.")
    base = "/mc/apps/" + config["app_id"]
    app = api("GET", base)
    container = the_container(app)

    image = config["image"]
    digest = api("POST", "/mc/registries/digest", {**image, "tag": image_tag})["digest"]
    require(bool(re.fullmatch(r"sha256:[0-9a-f]{64}", digest)), "Invalid registry digest.")
    if os.environ.get("IMAGE_DIGEST"):
        require(digest == os.environ["IMAGE_DIGEST"], "Registry digest differs from the built image.")

    patch = {
        **image, "imageTag": image_tag, "imageDigest": digest, "imagePullPolicy": "always",
        "environmentVariables": runtime_environment(container, config),
    }
    if any(str(container.get(key)) != str(value) for key, value in patch.items()):
        # A PATCH rolls the app out and keeps every setting it does not name.
        api("PATCH", base + "/containers/" + container["id"], patch)
    if app["status"] == "inactive":
        api("POST", base + "/deploy")
    print(f"Deploying {image_tag} ({digest}).", flush=True)

    deadline = time.monotonic() + 900
    last_status = None
    while time.monotonic() < deadline:
        overview = api("GET", base + "/overview")
        if overview["status"] != last_status:
            last_status = overview["status"]
            print(f"Bunny status: {last_status}", flush=True)
        require(last_status != "suspended", "App suspended during deployment.")
        if rolled_out(overview, digest):
            check_http(config["url"])
            print(f"Deployment verified: {image_tag}", flush=True)
            return
        time.sleep(5)
    raise RuntimeError("Deployment did not finish within 15 minutes. Inspect Bunny before retrying.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--image-tag", required=True, help="Full commit SHA of a pushed image")
    args = parser.parse_args()
    try:
        deploy(json.loads((ROOT / "bunny.json").read_text()), args.image_tag)
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.TimeoutExpired) as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
