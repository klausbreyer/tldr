# ADR-003: A YouTube video goes to Gemini as a video, through Google AI Studio

## Status
Accepted

## Date
2026-10-29

## Context
A video's content is in its picture as well as its words: a product review
shows the product, a talk shows its slides. OpenRouter passes a YouTube
address to Gemini as a `video_url` part, but only the Google AI Studio
provider accepts YouTube addresses. Vertex AI wants the file itself.

## Decision
`Tldr.Source` turns every YouTube address shape (`youtu.be`, shorts, live,
embed, extra parameters) into `https://www.youtube.com/watch?v=<id>`. The
request carries the address as a `video_url` part and pins the provider with
`provider: {only: ["google-ai-studio"]}`. YouTube's public oEmbed endpoint
gives the title and channel; the channel lets the model attribute opinions.

## Alternatives Considered

### The transcript through yt-dlp or a subtitle endpoint
- Pros: text is far cheaper than video tokens, works with any model
- Cons: a second tool on the host, scraping that YouTube breaks regularly,
  no picture, and many videos have only automatic subtitles or none
- Rejected: Gemini watching the video is the reason for choosing Gemini

### Downloading the video and sending it as base64
- Pros: works with Vertex and private videos
- Cons: a download per request, large payloads, yt-dlp on the host
- Rejected: AI Studio takes the address directly

## Consequences
- Only public videos work. A private or age-restricted video fails at Google.
- If AI Studio is down, YouTube summaries fail; there is no fallback provider.
- Video tokens cost more than text: a 19 second clip was about 1,700 input
  tokens, roughly 90 per second, so an hour is around 300,000 tokens. The
  1M context sets the upper limit at a few hours.
- A 51 minute video took about 30 seconds, so the interface needs a clear
  waiting state.
