# Google model comparison, 2026-10-29

## Result

Keep `google/gemini-3.8-flash` as the default. None of the cheaper candidates
was reliable enough to replace it with the current prompt.

Gemini 3.1 Flash Lite was the closest candidate. It was cheaper and faster,
but one response used the wrong language and others changed source claims.
Adding low reasoning fixed the language failures in this sample, but did
not fix factual accuracy. No model, prompt, or runtime setting changed.

## Method

The comparison used commit `26d0b9f` in a separate local worktree.
Each model summarized five sources in German and English, three times each:
30 summary attempts per model, 120 attempts for the initial comparison.
A follow-up ran the same 30 cases with Gemini 3.1 Flash Lite and
`reasoning: {effort: "low"}`. Total: 150 summary attempts.

| Case | Source |
| --- | --- |
| Essay | [Paul Graham: How to Do Great Work](https://paulgraham.com/greatwork.html) |
| Front page | [Hacker News](https://news.ycombinator.com/), one frozen snapshot |
| Thin page | [Example Domain](https://example.com/), 156 extracted characters |
| German video | [Kurzgesagt: Impfen & Nebenwirkungen](https://www.youtube.com/watch?v=4E0dwFS72gk) |
| Long video | [Andrej Karpathy: Intro to Large Language Models](https://www.youtube.com/watch?v=zjkBMFhNj_g), about 60 minutes |

All calls went through `Tldr.Summarizer.summarize/2`, including its response
validation and retry policy. A temporary Req plugin captured response usage
and timing without saving authentication headers. Web pages and video
metadata were fetched once and reused. Videos remained native `video_url`
inputs through Google AI Studio. Transcripts were used only for review.

Request hashes confirmed identical content, prompts, schemas, and routing
for each source and language. Only the model and the follow-up reasoning
field differed. Four calls ran concurrently in the initial comparison.
The follow-up used two concurrent calls and overlapped the end of the
initial comparison.

The agent reviewed all outputs against the extracted text and public video
captions. It checked factual meaning, requested language, useful coverage,
attribution, thin-source handling, and length. Language errors, material
claim reversals, and repeatable source failures ruled out a replacement.
This was an agent review, not a blind human evaluation.

## Measurements

Costs are USD reported in OpenRouter response usage. Times are the median
elapsed time per summary attempt, including application retries.

| Model | Valid responses | Wrong language | Thin page: no points | Median seconds | Reported cost |
| --- | ---: | ---: | ---: | ---: | ---: |
| Gemini 3.8 Flash, current | 30/30 | 0 | 5/6 | 10.16 | $0.86748 |
| Gemini 3.5 Flash Lite | 30/30 | 3 | 0/6 | 1.65 | $0.32331 |
| Gemini 3.1 Flash Lite | 30/30 | 1 | 0/6 | 1.93 | $0.26378 |
| Gemini 2.5 Flash Lite | 23/30 | 3 | 0/6 | 1.77 | $0.06274 |
| Gemini 3.1 Flash Lite, low reasoning | 30/30 | 0 | 0/6 | 5.00 | $0.35194 |

A valid response passed the application's format checks. It could still
contain factual errors or use the wrong language. Word limits were exceeded
in 0, 5, 6, 3, and 7 responses respectively, using whitespace word counts.

Total reported cost was **$1.86925**. Provider caching reduced repeat costs.
These totals are not estimates for 30 distinct uncached requests.
Failed requests did not report usage, so their cost is unknown here.
Gemini 2.5's total covers only 23 completed summaries.
Its cost and latency are not comparable to a complete workload.

The first German-video attempt used 59,237 input tokens on the newer models
and 190,877 on Gemini 2.5 Flash Lite. Their reported costs were:

| Model | First German-video attempt |
| --- | ---: |
| Gemini 3.8 Flash | $0.04762 |
| Gemini 3.5 Flash Lite | $0.01830 |
| Gemini 3.1 Flash Lite | $0.01511 |
| Gemini 2.5 Flash Lite | $0.02329 |

Gemini 2.5 was more expensive than both newer Lite models for this video,
despite its lower token price. All six long-video attempts exceeded its
1,048,576-token input limit.

## Why the candidates failed

**Gemini 3.5 Flash Lite:** all three German essay requests returned English.
All six thin-page responses expanded the placeholder into points. Two
returned only two points, outside the requested three-to-six range.

**Gemini 3.1 Flash Lite:** the third German essay response returned English.
The second German-video response called fever and rash very rare relative
to severe disease complications. The source distinguishes common mild
effects from rare severe effects. The second German thin-page response
turned advice against reliance into a prohibition and added unsupported
claims about automated systems.

**Gemini 2.5 Flash Lite:** all six long-video attempts failed with the
provider's input-limit error. One essay attempt exhausted retries with an
upstream shared-pool rate limit. All three English requests for the German
video returned German. The first German response listed middle-ear
infections and pneumonia as vaccine side effects. The source lists them
as measles complications. This changes the meaning of the source.

**Gemini 3.1 Flash Lite with low reasoning:** all responses used the correct
language, but factual errors remained. The third German essay response
advised against copying because it promotes intellectual dishonesty.
Graham explicitly permits copying and distinguishes honest copying from
unconscious imitation. The first German thin-page response changed
permission for documentation examples into permission for a test environment.
Ten of twelve video responses reported zero reasoning tokens, despite the
requested effort. This does not establish why the provider reported zero.

**The current model also has limits.** It expanded the thin page once,
sometimes omitted attribution, and overstated scaling laws as guarantees
in one German long-video response. However, it had no language failures,
passed all format checks, and preserved the German video's central numerical
comparison in all six runs. The evidence supports retaining it, not claiming
that it is error-free.

## Scope and reproducibility

This sample contains five sources, not a representative production corpus.
Results apply to this prompt, these provider defaults, and this run date.
Concurrency, caching, and provider load affect timing and cost. Review used
captions rather than a full visual audit of every video frame.

The temporary harness, frozen sources, individual outputs, usage records,
and review notes remain outside the repository. The source files below have
SHA-256 hashes so another local run can identify the snapshots:

| Source snapshot | SHA-256 |
| --- | --- |
| essay.txt | `ebfcf697a657869e20bf41d0464c66bea460c840ae2888e1f718a7c0530ada28` |
| front.txt | `50de6efb422c11226d2d9dbad13b602a58f5e9535cce6b09caf3289c82d46f48` |
| thin.txt | `0a080719be9fbb82a86a45b80dc8c2a430fbe17dc93d23758debac092864d00f` |

For a new content comparison, run `mix tldr --model <id> --language de
<address>` and repeat three times. Repeat with `--language en` and each
model. This CLI command does not freeze live pages, capture usage, or set
reasoning effort. The Hacker News front page will change.

Both source paths and languages were exercised. The existing error-path
tests passed with `make check`: 47 tests, no failures. The waiting state,
layout, prompt, and runtime behavior did not change.
