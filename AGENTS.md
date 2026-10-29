# tldr

tldr summarizes what is behind an address: a web page or a YouTube video.
Paste a link, get one sentence and a few points in German or English.
Phoenix and LiveView, Gemini through OpenRouter, no database.

## What makes tldr special?

These are the promises the product is built on. Keep them intact.

### 1. Web pages and YouTube, one box

One input takes any address. A web page is fetched and read, a YouTube
video is watched by Gemini itself, picture and sound. The reader never says
which kind it is.

### 2. Ten seconds to decide

A summary is one sentence and three to six short points. It says what the
source claims, not what it is about. Opinions carry their author's name.
When there is nothing to summarize, it says so and invents nothing.

### 3. Nothing is stored

No database, no accounts, no history. A request comes in, a summary goes
out, and nothing outlives it. A feature that needs to remember something
needs a decision first (`docs/decisions/001`).

## A note from Klaus

I like ambitious ideas, simple systems, and software that feels obvious. Do not
keep complexity because it is already there. Do not add machinery because it
looks architecturally impressive. Understand the real constraint, then fight for
the smallest model that makes the correct behavior unsurprising.

Channel both "measure twice, cut once" and YAGNI. Fight scope creep. Propose a
bold idea when it truly helps, and say so plainly instead of building it behind
my back.

A question is read-only. If I ask how hard something is, why something happens,
or whether something should be done, answer it and offer the change. Do not
start editing.

Match the ceremony to the task. One agent in one pass beats a panel for
ordinary work.

The rest of this file helps you find your way and make changes well. Treat it as
good defaults, not as scripture. My preferences in the moment beat anything
written here. If a rule fights the task in front of you, say so and get my
sign-off before breaking it.

## A small glossary

Use this language in code, in the UI and when talking to me.

- **you** means the agent reading this file and changing tldr.
- **we, us, maintainers** mean Klaus and the people building tldr.
- **address** means the URL a person pastes. Every word a person reads says
  address or link, never URL.
- **source** means what is behind the address: a **web page** or a **video**.
  `Tldr.Source` decides which.
- **summary** means what tldr gives back: the **tldr** (one sentence) and the
  **points**. `Tldr.Summary` is its struct.
- **the prompt** means the system prompt and the JSON schema in
  `Tldr.Summarizer`.
- **the key** means `OPENROUTER_API_KEY`.
- **language** means the reader's language, `de` or `en` (`Tldr.Language`). It
  sets the words of the interface and the language of new summaries.

## The three ways to hurt yourself

1. **Taking port 4000, or killing by pattern.** Port 4000 belongs to Klaus and
   to `make start`. Never bind it and never kill its process. Use 4441 to
   4449 for your own servers (`PORT=4441 mix phx.server`). Never `pkill -f`,
   never `pgrep | kill`, never kill a PID you found by matching a name or a
   worktree path. Kill only a PID you captured at spawn.
2. **Leaking or burning the key.** The key is real money. Never print it, never
   commit `.env`, never put it into a log, a test or a pull request. Every
   test stubs OpenRouter with `Req.Test`; a test that reaches the network is a
   bug. Prompt runs with `mix tldr` cost real money: run a handful of
   addresses, not a crawl. Ask Klaus before you need a production key.
3. **Reaching production.** Never deploy and never set secrets on a host unless
   you were told to. When a task is next to that, say exactly what you are
   about to touch before you touch it.

## Hit every surface

Before you call a change done, walk this list and say which entries applied.

- **Both kinds of source.** A web page and a YouTube video take different paths
  through `Tldr.Summarizer`. A change to one is checked against the other.
- **Every way it fails.** An invalid address, a blocked page (403), a missing
  page (404), a non-HTML answer, an empty page, an OpenRouter error, a slow
  video. Each one reaches the person as a plain sentence, never a stack trace.
- **Both languages.** Every sentence the interface says lives in
  `TldrWeb.Words`, in every language; its test fails when one is missing. A
  prompt change is checked in both languages with `mix tldr --language`.
- **The waiting state.** A long video takes half a minute. The interface shows
  that it is working with the `tldr-pulse` dot: an animation in `steps()`,
  a few frames a second, only while loading. A smooth endless animation
  (spinner, shimmer, blur) repaints on every display refresh and is out.
- **Phone and desktop.** Judge both screenshots together, phone first.
- **The prompt.** A change to the prompt or the schema is checked with
  `mix tldr` against a mix of sources (an essay, a front page, a thin page, a
  German video, a long video) before and after. Compare the output, not the
  diff.
- **Docs.** `README.md` is for the person running tldr: update it with any
  change to environment variables, ports or commands. `PHOENIX.md` is the
  framework guide. This file holds the permanent rules. `docs/decisions/`
  holds one record per decision that is expensive to reverse: write one in the
  change that makes such a decision, and read the existing ones before you
  re-decide something.

## Dev servers

- `make prepare` installs dependencies and assets.
- `make start` frees port 4000, prepares, runs the development server there
  and opens the browser. That one is Klaus's: never run `make start` or
  `make kill-port-4000` yourself. Start your own with
  `PORT=4441 mix phx.server`, up to 4449.
- Development needs only the key. A git-ignored `.env` in the main checkout is
  loaded from every worktree, and real environment variables win over it.
- While a server you started is running, every answer you give ends with
  one line that says so: the address, the port and the PID.
- Stop what you started, by the PID you tracked. See rule 1.

## Verifying

- **Write the failing test first.**
- Test the core with unit tests under `test/tldr`, with `Req.Test` stubs for
  every outside call. Test the interface with LiveView tests under
  `test/tldr_web`.
- Run `make check` (`mix precommit`) before a pull request. It compiles with
  warnings as errors, formats and runs the tests.
- A green test is not the end. Use the change in a real browser on your own
  server before you call it done, with a real address.
- Finish every UI change with the shared `visual-qa` skill in a headless
  browser. Judge the desktop and phone screenshots together.

## Commits and pull requests

- Never work on `main`. Follow the global worktree location and session
  rules. Klaus runs `make start` in the main checkout; it shows `main`, so a
  change is there for him once its pull request is merged.
- Branch names, commits and pull request text are English. Add no co-author.
- Rebase onto the latest `main` before you open a pull request.
- Open a normal pull request, never a draft. Title in plain language, body with
  the problem in a sentence or two and then how you solved it. End with the
  model and the harness that did the work.
- Every open pull request gets the shared `review-pr` skill.

## How it works

`Tldr.Summarizer.summarize/2` is the whole product:

1. `Tldr.Source.parse/1` refuses anything that is not a public http address
   and turns every YouTube shape into the canonical watch address.
2. A web page goes through `Tldr.Page.fetch/1`: Req, Floki, the readable text
   of `<article>`, `<main>` or `<body>`, sent to the model as text.
3. A video goes to the model as its address in a `video_url` part, pinned to
   Google AI Studio, the only provider that accepts YouTube addresses.
   `Tldr.YouTube.info/1` adds title and channel from oEmbed. Its preview
   image reaches the reader through `/thumbnail/:id`
   (`TldrWeb.ThumbnailController`), so the reader's browser never talks to
   YouTube.
4. `Tldr.OpenRouter.complete/1` makes the one call with a strict JSON schema
   and returns `tldr` and `points`.

Errors come back as `{:error, reason}` tuples all the way up. The interface
turns each reason into a sentence (`TldrWeb.SummaryLive.message/1`); a new
reason needs a new sentence there.

The reader's language comes from the `tldr_language` cookie, else the
browser's `Accept-Language`, else English (`put_language` in the router,
`docs/decisions/008`). The switch sets the cookie in the browser.

The interface is one LiveView, `TldrWeb.SummaryLive` at `/`. One summary gets
the single layout, two or more turn the page into a list, newest first. Each
address runs in its own `start_async` task. The list lives in the LiveView
process. Its addresses go into the address bar (`/<address><address>`),
and opening that address summarizes them again (`docs/decisions/011`). So
`tldr.tf/` in front of a link, or of several in a row, summarizes them. Next
to it, `TldrWeb.PrivacyLive` at `/privacy` says what happens to the reader's
data. The footer and the wordmark live in `TldrWeb.Layouts` and both pages
share them.

## Where code lives

- `lib/tldr/` holds the core: `source`, `page`, `you_tube`, `open_router`,
  `summarizer`, `summary`, `config`.
- `lib/tldr_web/live/summary_live.ex` is the interface,
  `lib/tldr_web/live/privacy_live.ex` the privacy page. `assets/js/app.js`
  holds the one bit of browser code, the copy button.
- `assets/css/app.css` holds the colors of v01.io as Tailwind theme colors
  (`brand`, `bg`, `text`, `line`; never `primary`, daisyUI owns that name).
  Like v01.io, text is `text` or `brand` and nothing in between: no dimmed
  grays. Hierarchy comes from size and weight. Only a placeholder is dimmed.
  The file also holds the wordmark font, Inter Tight 700 cut to the letters
  of "tldr.tf". A wordmark with other letters needs a new cut of the font.
- `lib/mix/tasks/tldr.ex` is `mix tldr`, the command line and the prompt bench.
- `test/tldr/` is unit, `test/tldr_web/` is controller and LiveView.
- Read `PHOENIX.md` before writing Phoenix code.

## Configuration and runtime

- tldr reads its configuration from environment variables at boot. In
  production a missing `OPENROUTER_API_KEY` stops the boot with a message
  that names it. `README.md` holds the table. Keep it true.
- Production is `https://tldr.tf` on Bunny Magic Containers. Every push to
  `main` deploys it (`.github/workflows/deploy.yml`, `scripts/deploy.py`,
  `docs/decisions/009`). A merge is a release.
- The model is `@model` in `Tldr.Summarizer`. Changing it is a decision
  (`docs/decisions/002`).

## Taste

- Keep it simple. Channel YAGNI unless told otherwise.
- Type safety where it earns its place, not everywhere.
- Comments explain how a thing is used and what is not obvious, not every line.
  A comment moves when its code moves.
- Complexity belongs at the edges: fetching, extraction, the model call. The
  summarizer stays plain and the UI stays dumb.
- Write focused tests that protect real behavior. No endless smoke tests, and no
  regression test for a feature that is gone.
- Be careful with anything destructive that Klaus did not ask for.

## Prose

- Apply the shared `ste-writing` skill to English pull request text,
  documentation and error messages. The interface speaks German and English,
  plainly, through `TldrWeb.Words`.
- Never use an em dash. Use a comma, a colon, parentheses or two sentences.
- Keep it short. A sentence a reader has to read twice is a sentence to rewrite.

## Shared skills

The personal skills live in `~/skills` and are loaded through the agent's global
configuration. Use `feature` for substantial feature work, `review-pr` for code
review, `visual-qa` for UI checks, and `ste-writing` for prose. In Claude these
commands have the `v01-skills:` prefix, for example `/v01-skills:review-pr`.
This repository keeps no local copies.
