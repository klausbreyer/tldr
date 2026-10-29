defmodule Tldr.Summarizer do
  @moduledoc """
  Turns an address into a `Tldr.Summary`.

  A web page is fetched here and sent as text. A YouTube video is sent as
  its address, and Gemini watches it itself. Only Google AI Studio accepts
  YouTube addresses, so those requests are routed there.
  """

  alias Tldr.{OpenRouter, Page, Source, Summary, YouTube}

  @model "google/gemini-3.8-flash"

  @system """
  You summarize a web page or a video for a busy reader who decides in ten
  seconds whether the source is worth their time.

  Write in German. Keep established English technical terms as they are.

  tldr: the core message in one sentence, at most 25 words. Say what the
  source actually claims or shows, not what it is about. Bad: "Der Artikel
  behandelt Microservices." Good: "Microservices machen Teams unabhängig,
  verlagern die Komplexität aber ins Netzwerk und in den Betrieb."

  When the source argues an opinion or makes an accusation, attribute it
  to the author or channel, in the tldr and in the points ("Graham rät
  ...", "Laut Brownlee ..."). Never state a disputed claim as fact.

  points: 3 to 6 points, each one short sentence of at most 20 words.
  - Concrete beats general: keep names, numbers, examples and conclusions.
  - Every point adds something the tldr does not already say.
  - Prefer the insight over trivia: skip license, publication details and
    housekeeping unless they are the point.
  - No filler and no hype words (extrem, hervorragend, zwingend,
    unerlässlich, revolutionär, spannend). No "Der Autor erklärt, dass ...",
    just say it.

  Ignore everything that is not the content: navigation, cookie notes,
  comments, related links, ads, sponsor segments, calls to subscribe.

  When the source is a list of many items (a front page, a feed, a search
  result), summarize what kind of items it lists and name the most
  prominent ones. When there is too little content to summarize (a paywall,
  a login wall, an error page), say that plainly in the tldr and return no
  points. Never invent content.
  """

  @schema %{
    name: "summary",
    strict: true,
    schema: %{
      type: "object",
      properties: %{
        tldr: %{type: "string", description: "The core message, one sentence."},
        points: %{
          type: "array",
          items: %{type: "string"},
          description: "3 to 6 short, concrete points."
        }
      },
      required: ["tldr", "points"],
      additionalProperties: false
    }
  }

  @doc """
  Summarizes the page or video at `url`.

  Options: `:model` replaces the default model.
  """
  @spec summarize(String.t(), keyword()) :: {:ok, Summary.t()} | {:error, term()}
  def summarize(url, opts \\ []) do
    with {:ok, {kind, url}} <- Source.parse(url),
         {:ok, title, content, extra} <- prepare(kind, url),
         {:ok, answer} <- OpenRouter.complete(request(content, extra, opts)) do
      {:ok,
       %Summary{
         url: url,
         kind: kind,
         title: title,
         tldr: answer["tldr"],
         points: answer["points"] || []
       }}
    end
  end

  @doc "The default model."
  def model, do: @model

  defp prepare(:web, url) do
    with {:ok, %Page{title: title, text: text}} <- Page.fetch(url) do
      if text == "" do
        {:error, :empty_page}
      else
        prompt = "Summarize this web page.\n\nTitle: #{title}\nAddress: #{url}\n\n#{text}"
        {:ok, title, [%{type: "text", text: prompt}], %{}}
      end
    end
  end

  defp prepare(:youtube, url) do
    %{title: title, channel: channel} = YouTube.info(url)

    content = [
      %{
        type: "text",
        text: "Summarize this YouTube video.\n\nTitle: #{title}\nChannel: #{channel}"
      },
      %{type: "video_url", video_url: %{url: url}}
    ]

    {:ok, title, content, %{provider: %{only: ["google-ai-studio"]}}}
  end

  defp request(content, extra, opts) do
    Map.merge(
      %{
        model: Keyword.get(opts, :model, @model),
        messages: [%{role: "system", content: @system}, %{role: "user", content: content}],
        response_format: %{type: "json_schema", json_schema: @schema}
      },
      extra
    )
  end
end
