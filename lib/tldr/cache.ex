defmodule Tldr.Cache do
  @moduledoc """
  Finished summaries, shared by every reader for a day
  (`docs/decisions/013`).

  One row per address and language, without anything about who asked. A
  database that fails is a miss: the summary then runs as if nothing was
  kept, and a summary that cannot be saved is only not kept.
  """

  import Ecto.Query

  alias Tldr.{Repo, Summary}

  require Logger

  @lifetime_hours 24
  @fields [:kind, :title, :channel, :tldr, :points, :saved_at]

  @doc "The summary of `url` in `language` from the last day, with the time it was saved."
  @spec fetch(String.t(), String.t()) :: {:ok, Summary.t(), DateTime.t()} | :miss
  def fetch(url, language) do
    query =
      from(s in "summaries",
        where: s.url == ^url and s.language == ^language and s.saved_at > ^expiry(),
        select: map(s, ^[:url | @fields])
      )

    case Repo.one(query) do
      nil -> :miss
      row -> {:ok, summary(row), row.saved_at}
    end
  rescue
    error in [DBConnection.ConnectionError, Postgrex.Error] ->
      Logger.warning("Cache read failed: #{Exception.message(error)}")
      :miss
  end

  @doc "Keeps `summary` in `language`, replaces an older one and deletes expired ones."
  @spec put(Summary.t(), String.t()) :: :ok
  def put(%Summary{} = summary, language) do
    row =
      summary
      |> Map.take([:url, :title, :channel, :tldr, :points])
      |> Map.merge(%{
        language: language,
        kind: Atom.to_string(summary.kind),
        saved_at: DateTime.utc_now()
      })

    Repo.insert_all("summaries", [row],
      on_conflict: {:replace, @fields},
      conflict_target: [:url, :language]
    )

    Repo.delete_all(from(s in "summaries", where: s.saved_at <= ^expiry()))
    :ok
  rescue
    error in [DBConnection.ConnectionError, Postgrex.Error] ->
      Logger.warning("Cache write failed: #{Exception.message(error)}")
      :ok
  end

  defp expiry, do: DateTime.add(DateTime.utc_now(), -@lifetime_hours, :hour)

  defp summary(row) do
    %Summary{
      url: row.url,
      kind: String.to_existing_atom(row.kind),
      title: row.title,
      channel: row.channel,
      tldr: row.tldr,
      points: row.points
    }
  end
end
