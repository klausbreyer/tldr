# ADR-007: One page; a single summary becomes a list from the second one

## Status
Accepted

## Date
2026-10-29

## Context
Four interface mocks were shown on 2026-10-29: A, one input and one calm
summary; B, a list of summaries with parallel requests; C, two columns with
the session on the left; D, a prefix address (`tldr.local/<address>`) or a
bookmarklet. Klaus chose a combination of A and B: A while there is one
summary, B as soon as there are several.

## Decision
One LiveView, `TldrWeb.SummaryLive`, at `/`. With no summary or one, the page
uses the single layout: a centered input and a large tldr. From the second
summary on it becomes a list, newest first, with a compact input bar on top.
An input can hold several addresses (`Tldr.Source.addresses/1`); each one runs
in its own `start_async` task, so they run at the same time. The list lives
in the LiveView process. A reload empties it. Every error reason becomes one
German sentence (`TldrWeb.SummaryLive.message/1`). Waiting is plain text, with
no spinner. "Kopieren" copies title, tldr, points and address as plain text.

## Alternatives Considered

### Only A
- Cons: a second link replaces the first, so comparing two sources is not
  possible
- Rejected: Klaus wants several at once

### Only B
- Cons: the first summary looks like a list row, which is busier than needed
  for the common case of one link
- Rejected: the single case deserves the calm layout

### C, two columns
- Cons: more chrome, and on a phone it collapses into B anyway
- Rejected

### D, a prefix address or bookmarklet
- Pros: no typing at all
- Open: not built now. It fits on top of this page later as a route

## Consequences
- No history across reloads, in line with ADR-001.
- Many parallel videos mean many parallel OpenRouter calls. There is no limit
  yet; add one if it ever costs real money.

## Amendment, 2026-10-29
Plain waiting text was not clear enough. Waiting now shows a pulsing dot,
stepped to about five frames a second (`.tldr-pulse` in `assets/css/app.css`),
next to "Gemini schaut das Video …" or "Gemini liest die Seite …".
