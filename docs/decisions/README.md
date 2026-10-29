# Architecture decision records

One file per decision that would be expensive to reverse: why it was made,
what it ruled out, and what it costs. The code shows what was built; these
files say why.

## How to add one

- Copy the headings of any record: Status, Date, Context, Decision,
  Alternatives Considered, Consequences.
- Number it next in line, `007-short-title.md`, and link it from the table.
- Never delete or rewrite a record. When a decision changes, write a new one
  that supersedes the old, and mark the old one superseded.
- No em dash.

## The records

| ADR | Decision | Date |
| --- | --- | --- |
| [001](001-one-phoenix-app-no-database.md) | One Phoenix app, no database | 2026-10-29 |
| [002](002-gemini-through-openrouter.md) | Gemini through OpenRouter, one default model | 2026-10-29 |
| [003](003-youtube-goes-to-gemini-as-a-video.md) | A YouTube video goes to Gemini as a video, through Google AI Studio | 2026-10-29 |
| [004](004-web-pages-are-fetched-here-and-sent-as-text.md) | A web page is fetched here and sent as plain text | 2026-10-29 |
| [005](005-the-summary-is-structured-json-in-german.md) | The summary is structured JSON in German: one tldr, a few points | 2026-10-29 |
| [006](006-the-key-lives-in-the-environment.md) | The key lives in the environment; dev reads the main checkout's `.env` | 2026-10-29 |
