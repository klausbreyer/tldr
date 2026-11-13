# ADR-013: A shared cache in Postgres for a day

## Status
Accepted. Supersedes "no database" of ADR-001, and the per-tab key, the ten
minutes in memory and the copy in the browser of ADR-012.

## Date
2026-11-13

## Context
Every request for an address costs a model call, also when another reader
asked for the same address a minute ago. A video of an hour costs about
0.25 USD each time. The browser copy of ADR-012 helps only the reader who
made it, and only in that browser. Klaus asked for a cache on the server,
shared by every reader, for 24 hours, with a button to summarize again.

## Decision
One Postgres table, `summaries`: the address, the language, the fields of
`Tldr.Summary` and the time it was saved. The key is the address (without
its fragment) and the language. `Tldr.Cache` reads and writes it.

`Tldr.Job.summarize/2` takes a summary of the last 24 hours from the cache.
Otherwise it starts or joins the one job of that address and language. The
job puts a summary into the cache, but not an error, and ends. The page
shows when a cached summary was saved and a button to summarize again. That
skips the cache and replaces the row for every reader.

Every write deletes the rows older than 24 hours. A database that fails is
a miss, so tldr goes on without the cache. A release runs the migrations at
boot (`Ecto.Migrator` in `Tldr.Application`). The database runs at Hetzner.
Production reads it from `DATABASE_URL`; dev and test use a local Postgres
and never read that variable.

The browser keeps nothing, and the tab id is gone. On its first load the
new code deletes what earlier versions kept in the browser.

## Alternatives Considered

### ETS on the one machine
- Pros: no database, no new dependency
- Cons: every deploy empties it, and a second machine has its own
- Rejected: a deploy on every merge would empty it several times a day

### Keep the browser copy next to the server cache
- Pros: a summary shows before the socket asks the server
- Cons: two places that keep the same thing, and two to explain on the
  privacy page. A cache hit takes milliseconds
- Rejected

### Cache errors too
- Pros: a blocked page costs nothing on the second try
- Cons: a short failure would block an address for a day
- Rejected: an error runs again on the next request

## Consequences
- The same address in the same language costs one model call a day.
- A reader can learn that someone summarized an address in the last day
  (they get a summary at once, with its time). Nothing says who.
- The privacy page names the cache, its 24 hours and Hetzner.
- Expired rows stay until the next write. With no traffic they stay longer
  than 24 hours, but no reader sees them.
- A release needs the database when it starts, to migrate. A database
  that fails later only empties the cache.
- A deploy needs the `DATABASE_URL` secret in GitHub. Without it the deploy
  stops before it changes Bunny.
- Tests need a local Postgres. CI starts one as a service.
