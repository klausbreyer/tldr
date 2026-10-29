# Architecture decision records

One file per decision that would be expensive to reverse: why it was made,
what it ruled out, and what it costs. The code shows what was built; these
files say why.

## How to add one

- Copy the headings of any record: Status, Date, Context, Decision,
  Alternatives Considered, Consequences.
- Number it next in line, `009-short-title.md`, and link it from the table.
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
| [005](005-the-summary-is-structured-json-in-german.md) | The summary is structured JSON in German: one tldr, a few points (language part superseded by 008) | 2026-10-29 |
| [006](006-the-key-lives-in-the-environment.md) | The key lives in the environment; dev reads the main checkout's `.env` | 2026-10-29 |
| [007](007-one-page-a-single-summary-becomes-a-list.md) | One page; a single summary becomes a list from the second one (reload part superseded by 010) | 2026-10-29 |
| [008](008-the-reader-chooses-german-or-english.md) | The reader chooses German or English; the browser decides first | 2026-10-29 |
| [009](009-production-runs-on-bunny-and-main-deploys.md) | Production runs on Bunny Magic Containers; every push to main deploys | 2026-10-29 |
| [010](010-the-addresses-live-in-the-address-bar.md) | The addresses live in the address bar, so the page can be shared | 2026-10-29 |
