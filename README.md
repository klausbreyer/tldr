# tldr

Paste a link to a web page or a YouTube video and get a short summary in
German: one sentence and a few points. Gemini through OpenRouter does the
reading and watching. No database.

## Quick start

1. Install Elixir 1.19 and Erlang/OTP 28.
2. `cp .env.example .env` and put your OpenRouter key into it.
3. `mix setup`
4. `mix phx.server` and open http://localhost:4000

## Commands

| Command | Description |
| --- | --- |
| `mix phx.server` | Development server on port 4000 (`PORT` changes it) |
| `mix tldr <address> ...` | Summarize addresses on the command line |
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

## Cost

The default model is `google/gemini-3.8-flash`. An article costs a fraction
of a cent. A video costs about 90 input tokens per second, so an hour is
roughly 300,000 tokens, around 0.25 USD.

## Architecture

See `AGENTS.md` for how it works and `docs/decisions/` for why.
