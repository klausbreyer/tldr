# ADR-004: A web page is fetched here and sent as plain text

## Status
Accepted

## Date
2026-10-29

## Context
For a web page the model needs its content. Raw HTML is many times the
tokens of its text, and most of it is navigation, scripts and styling.

## Decision
`Tldr.Page` fetches the address with Req and parses it with Floki. The title
is `og:title` or `<title>`. The text comes from `<article>`, else `<main>`,
else `<body>`, without scripts, navigation, header, footer, asides and forms.
Block elements end a line. The text is cut at 150,000 characters. Only a
`200` HTML answer counts; anything else is an error that names the cause.

## Alternatives Considered

### Sending the HTML
- Pros: no extraction code, the model sees the structure
- Cons: several times the tokens for the same content
- Rejected: cost and noise

### A readability library or headless browser
- Pros: better extraction on difficult pages, JavaScript-rendered pages work
- Cons: a large dependency or a browser on the host
- Rejected for now: the simple extraction worked on every test page, X
  included

### OpenRouter's web plugin, the model fetches the page
- Pros: no fetching code
- Cons: less control, another paid feature, results depend on a search index
- Rejected: the page is one GET away

## Consequences
- Sites that block automatic requests (the New York Times answered 403) can
  not be summarized. The interface must say so plainly.
- PDFs and other non-HTML addresses are refused for now.
- Pages that render everything with JavaScript give little text. The model is
  told to say "too little content" instead of inventing.
