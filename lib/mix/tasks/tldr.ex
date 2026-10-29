defmodule Mix.Tasks.Tldr do
  @shortdoc "Summarizes a web page or YouTube video"

  @moduledoc """
  Summarizes one or more addresses on the command line.

      mix tldr https://paulgraham.com/greatwork.html
      mix tldr --model google/gemini-3.5-flash-lite https://youtu.be/jNQXAC9IVRw

  Reads `OPENROUTER_API_KEY` from `.env` like the dev server does.
  """

  use Mix.Task

  @requirements ["app.config"]

  @impl true
  def run(args) do
    {opts, urls} = OptionParser.parse!(args, strict: [model: :string])
    Application.ensure_all_started(:req)

    urls
    |> Task.async_stream(&{&1, timed(fn -> Tldr.Summarizer.summarize(&1, opts) end)},
      timeout: :infinity,
      max_concurrency: 8
    )
    |> Enum.each(fn {:ok, {url, {ms, result}}} -> print(url, ms, result) end)
  end

  defp timed(fun) do
    {us, result} = :timer.tc(fun)
    {div(us, 1000), result}
  end

  defp print(url, ms, {:ok, summary}) do
    Mix.shell().info("""
    # #{summary.title || url}
    #{url} (#{summary.kind}, #{ms} ms)

    #{summary.tldr}

    #{Enum.map_join(summary.points, "\n", &"- #{&1}")}
    """)
  end

  defp print(url, ms, {:error, reason}) do
    Mix.shell().error("# #{url} (#{ms} ms)\nError: #{inspect(reason)}\n")
  end
end
