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
