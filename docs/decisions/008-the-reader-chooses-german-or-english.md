# ADR-008: The reader chooses German or English; the browser decides first

## Status
Accepted. Supersedes the language part of ADR-005.

## Date
2026-10-29

## Context
ADR-005 fixed the summaries to German. Klaus asked for a language choice,
with the browser's language as the default and English as the fallback.

## Decision
Two languages, `de` and `en` (`Tldr.Language`), for the interface and the
summaries. The router plug `put_language` takes the `tldr_language` cookie,
else the first known language of `Accept-Language` by quality, else English,
and hands it to the LiveView in the session. "DE EN" on the page switches the
words at once; the browser sets the cookie for the next visit. The server
stores nothing.

The prompt names the language (`Write in {language}`) and its examples are
English. `Summarizer.summarize/2` and `mix tldr` take `language:`; English is
the default. The interface words live in `TldrWeb.Words`, a plain map per
language, and a test fails when a language misses a sentence.

Summaries that are already on the page keep their language when the reader
switches. Errors and waiting texts switch, because they are words of the
interface.

## Alternatives Considered

### The language of the source
- Rejected: a German reader of an English page wants German

### Any language the browser names
- Pros: Gemini writes many languages
- Cons: the interface would need every one of them too
- Rejected for now: adding a language is one map in `TldrWeb.Words` and one
  name in `Tldr.Language`

### Gettext
- Pros: the Phoenix standard, tools for translators
- Cons: a dependency, extraction and `.po` files for about twenty sentences
- Rejected: a map is enough at this size. Move to Gettext when a translator
  who is not a developer joins

### Summarizing again on a switch
- Rejected: it costs a model call per summary for a click
