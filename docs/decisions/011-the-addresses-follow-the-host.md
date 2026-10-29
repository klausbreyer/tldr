# ADR-011: The addresses follow the host

## Status
Accepted. Supersedes the `/?a=` form of ADR-010.

## Date
2026-10-29

## Context
Klaus wants to summarize a link without opening tldr first: put `tldr.tf/`
in front of it in the address bar. ADR-010 rejected this form because the
link's own query collides with ours and several links do not fit. Two
forms of the same page are one too many, so `/?a=` goes.

## Decision
The page lives at every path. Everything after the host is a paste: the
raw path and the raw query string, so the query of an address stays its
own and is never parsed. `Tldr.Source.addresses/1` splits it as it splits
the input box: a new address starts at each `http://` or `https://`, except
right after `=`. A `//` that a proxy merged into `/` is put back. A path
that does not start with an address is not found.

The address bar shows the page's addresses back to back, in the order
shown: `/<address><address>`. Each one is in its full form (the canonical
watch address for a video), without its fragment. An address that is not
valid is left out. Old `/?a=` links show the empty page.

## Alternatives Considered

### Keep `/?a=` and redirect the prefix form to it
- Pros: no ambiguity in the address bar
- Cons: two forms; the one people type is not the one they see
- Rejected

### A separator that never appears in addresses
- Pros: no guessing where an address ends
- Cons: a space starts a search in the address bar; browsers encode `|`
  and its kind as `%7C`, which real addresses contain too; nobody knows it
- Rejected

## Consequences
- Several links work back to back: `tldr.tf/<link><link>`.
- A link that holds another link in its path (Wayback:
  `web.archive.org/web/2024/https://...`) is split in two. So is an
  address that ends with `=` and the one after it.
- A `#fragment` never reaches the server and is lost.
- A mistyped path that starts with an address costs a model call once the
  page connects, as a typed address does.
