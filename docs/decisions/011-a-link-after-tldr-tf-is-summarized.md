# ADR-011: A link after tldr.tf/ is summarized

## Status
Accepted. Supersedes the rejected "prefix address" alternative of ADR-010.

## Date
2026-10-29

## Context
Klaus wants to summarize a link without opening tldr first: put `tldr.tf/`
in front of it in the address bar. ADR-010 rejected this form because the
link's own query collides with ours and several links do not fit.

## Decision
Every path that starts with `http://` or `https://` is a paste. The paste
is the raw path and the raw query string, so the link's query stays its
own and is never parsed. `Tldr.Source.addresses/1` splits it as it splits
the input box: a new address starts at each `http://` or `https://`, except
right after `=`. A `//` that a proxy merged into `/` is put back. Then a
redirect goes to the shared form `/?a=...`, so the address bar shows one
form only. Any other path is not found.

## Alternatives Considered

### A separator that never appears in addresses
- Pros: no guessing where an address ends
- Cons: a space starts a search in the address bar; browsers encode `|`
  and its kind as `%7C`, which real addresses contain too; nobody knows it
- Rejected

### Show the summaries at the prefix address itself
- Pros: no redirect
- Cons: two forms of the same page; ADR-010's sharing works on one
- Rejected

## Consequences
- Several links work back to back: `tldr.tf/<link><link>`.
- A link that holds another link in its path (Wayback:
  `web.archive.org/web/2024/https://...`) is split in two. The input box
  and `?a=` do the same.
- A `#fragment` never reaches the server and is lost.
- A mistyped path that starts with an address costs a model call once the
  page connects, as a typed address does.
