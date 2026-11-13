# ADR-012: Summaries outlive their page

## Status
Accepted. Narrows "nothing is kept" of ADR-001. The per-tab key, the ten
minutes in memory and the copy in the browser are superseded by ADR-013.

## Date
2026-11-07

## Context
Safari on a phone freezes a page when the reader switches to another app,
and its connection drops. The page process ends, and its summaries end
with it. When the reader comes back, the page connects again and starts
every summary from zero. A reader who switches often never sees a result.

## Decision
Two parts, both as small as the problem allows.

The server runs each summary as a `Tldr.Job`, apart from the page process.
The key is the browser tab, the address and the language. A page that
comes back with the same tab id joins the running job or takes its
result. The job keeps a result in memory for ten minutes, then ends. An
error runs again on the next ask. A tab only finds its own jobs.

The reader's browser keeps their last 50 summaries in `localStorage`, with
the date they were saved. On connect, the browser sends the ones for the
addresses in the address bar. The page shows them at once, with the date,
and a button to summarize again.

## Alternatives Considered

### A server cache shared by all readers
- Pros: a second reader of the same address pays nothing
- Cons: one reader can learn what another summarized; stale summaries for
  everyone; a store to size and expire
- Rejected: the problem is one reader's own tab

### IndexedDB in the browser
- Pros: more room, asynchronous
- Cons: asynchronous is the wrong shape: the summaries must be ready when
  the socket connects. 50 summaries fit in `localStorage` many times over
- Rejected

## Consequences
- A restart of the server forgets running jobs. The browser's kept
  summaries survive it.
- The privacy page says what the browser keeps and that the server holds a
  finished summary for ten minutes.
- With several machines, a page that reconnects to another machine starts
  the summary again. One machine runs today.
