# ADR-001: One Phoenix app, no database

## Status
Accepted

## Date
2026-10-29

## Context
tldr takes an address and gives back a summary. Nothing has to outlive the
request: there are no accounts, no history and no shared state. Klaus asked
for Elixir and explicitly for no database.

## Decision
One Phoenix application without Ecto (`mix phx.new --no-ecto`). The core is
plain modules under `lib/tldr/`: `Source` classifies the address, `Page`
fetches a web page, `YouTube` names a video, `OpenRouter` makes the one model
call, and `Summarizer` ties them together. The same core serves the web
interface and `mix tldr`.

## Alternatives Considered

### Phoenix with SQLite or Postgres for a history or cache
- Pros: a list of past summaries, no second bill for the same address
- Cons: a schema, migrations and a volume for a feature nobody asked for
- Rejected: YAGNI. A cache can live in ETS if repeat calls ever cost real money

### A plain Mix project with only a command line
- Pros: even smaller
- Cons: no web interface, which is the main way to use it
- Rejected: the interface is part of the request

## Consequences
- A restart forgets everything, which is fine because nothing is kept.
- Any future history or cache needs a new decision and supersedes this one.
- The app is stateless, so it can run on any host, on any number of machines.
