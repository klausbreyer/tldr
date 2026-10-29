# ADR-009: Production runs on Bunny Magic Containers; every push to main deploys

## Status
Accepted

## Date
2026-10-29

## Context
tldr needs a public home at `tldr.tf`. Klaus's other Phoenix apps (medixir,
texttile) run on Bunny Magic Containers, deployed from GitHub Actions. tldr
keeps no state (ADR-001), so it needs no volume and no database.

## Decision
`tldr.tf` runs as the Bunny app `tldr`, one shared instance in Germany,
behind the CDN zone Bunny made for the app. Cloudflare keeps the DNS and
points the apex at the zone, unproxied. The workflow `deploy.yml` tests every
change; a push to `main` also pushes the image `ghcr.io/klausbreyer/tldr`
tagged with the commit and runs `scripts/deploy.py`. The script patches the
image and the environment, waits until every pod runs the new digest and
checks `/healthz` and the page over HTTPS. `/healthz` answers before the
session and outside force_ssl, so Bunny's probes can ask over plain HTTP.

The key lives in a GitHub secret and every deploy writes it to Bunny.
`SECRET_KEY_BASE` lives only in Bunny and the deploy keeps it.

## Alternatives Considered

### Fly.io
- Rejected: medixir and texttile moved away from it; one host for all apps

### Deploy on a version tag instead of on main
- Rejected: one person, one app; main is what runs

### The key only in Bunny, like `SECRET_KEY_BASE`
- Rejected: a GitHub secret is one command to set or rotate, and the next
  deploy carries it

## Consequences
- A merge to main is a release. A red test stops it before the image.
- Rotating the key is `gh secret set OPENROUTER_API_KEY` and a new deploy.
- A deploy restarts the instance, and the reader's list of summaries goes
  with it (ADR-007).
