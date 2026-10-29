# ADR-010: The addresses live in the address bar

## Status
Accepted. Supersedes the "a reload empties it" part of ADR-007.

## Date
2026-10-29

## Context
Klaus wants to share what is on the page by copy and paste: one summary or
several. Nothing is stored (ADR-001), so a summary cannot be shared by itself.
Its address can.

## Decision
Every submit patches the address bar to `/?a=<address>+<address>`, the
addresses in the order the page shows them. The patch replaces the history
entry, so Back leaves the page instead of stepping through it. Only `&`, `#`,
`+`, `%` and spaces are escaped, so the addresses stay readable. A page that
opens with `a` and no summaries yet summarizes every address again, in the
reader's language. The summaries start only when the LiveView connects, so a
crawler that unfurls a shared link costs nothing.

## Alternatives Considered

### Store the summary and share an id
- Cons: needs storage, against ADR-001
- Rejected

### Put the summary text into the address
- Pros: no new model call
- Cons: long, ugly addresses; anyone can forge a summary under tldr.tf
- Rejected

### A prefix address, `tldr.tf/<address>`
- Pros: nice for one link
- Cons: the inner address's own query collides with ours; several links do
  not fit
- Rejected for now

## Consequences
- Opening or reloading a shared address costs one model call per address.
- The reader of a shared link can get a slightly different summary, and one
  in their own language.
- The language is not in the address. ADR-008 still decides it.
