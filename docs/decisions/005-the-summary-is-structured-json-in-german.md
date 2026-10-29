# ADR-005: The summary is structured JSON in German: one tldr, a few points

## Status
Accepted

## Date
2026-10-29

## Context
The reader wants to decide in seconds whether a source is worth their time.
Free Markdown from a model varies in shape from call to call, and rendering
model HTML in the page is a risk.

## Decision
The request sets `response_format` to a strict JSON schema: `tldr`, one
sentence of at most 25 words, and `points`, 3 to 6 sentences of at most 20
words. The system prompt in `Tldr.Summarizer` asks for German, concrete
points, attribution of opinions to their author or channel, no hype words,
and an honest "too little content" with no points for paywalls and empty
pages. The interface renders the two fields as plain text.

The prompt was tuned over four rounds against essays, a technical article,
the Spiegel front page, GitHub, X, example.com, a blocked page, a German
science video, a product review, a 51 minute video essay and a short
explainer. The fourth round fixed the last real defect: an accusation stated
as fact in the tldr.

## Alternatives Considered

### Markdown with free structure
- Pros: the model can use headings, tables and emphasis where they help
- Cons: varying shape, needs a Markdown renderer and HTML sanitizing
- Rejected: the fixed shape is the product

### The source's language
- Pros: no translation
- Cons: Klaus reads German; a mixed list of German and English summaries reads worse
- Rejected for now: a language switch is one prompt line if it is ever wanted

## Consequences
- A new field (a verdict, timestamps, reading time) is a schema change plus
  an interface change.
- Prompt changes are checked with `mix tldr <addresses>` against the same
  kind of mix, not with unit tests: the tests stub the model.
