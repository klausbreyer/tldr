# tldr

Paste a link to a web page or a YouTube video and get a short summary in
German or English: one sentence and a few points. The language follows the
browser and can be switched on the page. Gemini through OpenRouter does the
reading and watching. No database.

## Quick start

1. Install Elixir 1.19 and Erlang/OTP 28.
2. `cp .env.example .env` and put your OpenRouter key into it.
3. `make start`: prepares everything, starts the server on port 4000 and
   opens http://localhost:4000

## Commands

| Command | Description |
| --- | --- |
| `make start` | Free port 4000, prepare, start the server, open the browser |
| `make prepare` | Install dependencies and assets (`mix setup`) |
| `make check` | What a pull request needs (`mix precommit`) |
| `mix phx.server` | Development server on port 4000 (`PORT` changes it) |
| `mix tldr <address> ...` | Summarize addresses on the command line |
| `mix tldr --language de <address>` | Same, in German (default English) |
| `mix tldr --model <id> <address>` | Same, with another OpenRouter model |
| `mix test` | Tests, every outside call stubbed |
| `mix precommit` | Compile with warnings as errors, format, test |

## Configuration

| Variable | Required | Description |
| --- | --- | --- |
| `OPENROUTER_API_KEY` | yes | OpenRouter key. Dev reads it from the main checkout's `.env`. |
| `PORT` | no | HTTP port, default 4000 |
| `SECRET_KEY_BASE` | prod | `mix phx.gen.secret` |
| `PHX_HOST` | prod | Public host name |
| `CHROME_EXTENSION_ID` | no | Allow this Chrome extension to embed tldr. No external embedding by default. |

## Chrome extension

`extension/` contains a Manifest V3 extension. The icon summarizes the current
page. The link context menu summarizes its target. Both show the existing
tldr page in a side panel, with no separate API or summary interface.
The side panel hides the address form. Its logo and footer links open the
website in a new tab. The language switch stays available.

The extension passes addresses as `https://tldr.tf/https://example.com/`.
It has no history, content scripts, or persistent storage. Opening a source
again can start another summary, as on the website.

For a local preview (Node.js 22 or later):

```sh
node scripts/prepare-extension.mjs /tmp/tldr-extension http://localhost:4448
CHROME_EXTENSION_ID=PASTE_PRINTED_ID PORT=4448 mix phx.server
```

Choose a free port from 4441 to 4449. Use the same port in both commands.
The preparation command creates a new directory and refuses to overwrite one.

1. Open `chrome://extensions` in Chrome 116 or later.
2. Enable Developer mode.
3. Select **Load unpacked** and choose `/tmp/tldr-extension`.
4. Pin tldr and click its icon on a web page or YouTube video.
5. Right-click a link and select **Summarize with tldr**.

Unsupported addresses, such as Chrome settings, open the empty tldr page.
The extension requests `activeTab`, `contextMenus`, `sidePanel`, and access
only to the tldr host. The extension does not read cookies. The embedded
page uses separate secure, partitioned session and language cookies. Its
language preference is separate from the website preference. LiveView uses
`/embedded-live` in an iframe and `/live` in an ordinary tab.

Embedded pages require HTTPS, except on `localhost` for development.

For the hosted site, load `extension/` directly and configure the server with
its extension ID. Until that server change is deployed, Chrome blocks the iframe.
The manifest includes the Web Store public key for a stable extension ID:
`jnhafnmghjfpcbmijehgdoiekilggkdj`. It contains no private key. `bunny.json`
sets `CHROME_EXTENSION_ID` to this ID for production deployments.

Package only the contents of `extension/` for the store. Store review and
deployment are separate steps. `make check` also runs the extension tests.

## Production

https://tldr.tf runs on Bunny Magic Containers: app `tldr`
(`1IKrsZEVi2UIYlP`), one instance in Germany. Every push to `main` runs the
tests, pushes the image `ghcr.io/klausbreyer/tldr:<commit>` and deploys it
with `scripts/deploy.py`. The script waits until the new image runs and
checks `/healthz` and the page over HTTPS. A pull request runs the tests and
builds the image, nothing more.

`bunny.json` holds the app, the image and the plain environment. The
secrets:

| Secret | Where | How to set it |
| --- | --- | --- |
| `OPENROUTER_API_KEY` | GitHub, written to Bunny on every deploy | `gh secret set OPENROUTER_API_KEY --repo klausbreyer/tldr` |
| `BUNNYNET_API_KEY` | GitHub, for the deploy | `gh secret set BUNNYNET_API_KEY --repo klausbreyer/tldr` |
| `SECRET_KEY_BASE` | Bunny only, kept by every deploy | Bunny dashboard, app `tldr` |

`tldr.tf` is a hostname on the app's CDN zone (`6888217`). Cloudflare holds
the DNS: a CNAME from the apex to `mc-b31duv111g.b-cdn.net`, not proxied.

## Cost

The default model is `google/gemini-3.8-flash`. An article costs a fraction
of a cent. A video costs about 90 input tokens per second, so an hour is
roughly 300,000 tokens, around 0.25 USD.

The [Google model comparison](docs/benchmarks/2026-10-29-google-models.md)
records why cheaper Flash Lite models did not replace the default.

## Architecture

See `AGENTS.md` for how it works and `docs/decisions/` for why.
