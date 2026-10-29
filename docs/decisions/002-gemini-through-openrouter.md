# ADR-002: Gemini through OpenRouter, one default model

## Status
Accepted

## Date
2026-10-29

## Context
YouTube must work, and Gemini is the model family that watches a YouTube
video from its address. Klaus wants the call to go through OpenRouter with
his key. In October 2026 OpenRouter lists `google/gemini-3.8-flash` as the
newest Flash model, with video input, a 1M token context, and 0.825 USD per
million input tokens and 4.125 USD per million output tokens.

## Decision
Every summary is one call to OpenRouter's `/api/v1/chat/completions` with
`google/gemini-3.8-flash` (`Tldr.Summarizer.model/0`). `Summarizer.summarize/2`
and `mix tldr --model` take another model for comparison. Req makes the call;
there is no OpenRouter SDK.

## Alternatives Considered

### Google's Gemini API directly
- Pros: one hop fewer, native `media_resolution` and file upload options
- Cons: a second account and key; Klaus wants OpenRouter
- Rejected: OpenRouter covers what tldr needs

### A Pro model
- Pros: better on long, dense sources
- Cons: about 2.5 times the input price and slower
- Rejected for the default: Flash gave good summaries in the prompt tests.
  `--model` stays for the cases where it does not

### Flash Lite
- Pros: about a third of the price
- Cons: untested quality
- Open: worth one comparison run with `mix tldr --model`

## Consequences
- A model that OpenRouter retires breaks every call. The fix is one module
  attribute.
- Cost is per call: the prompt tests cost a fraction of a cent for an article
  and a few cents for a long video.
