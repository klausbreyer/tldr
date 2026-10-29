defmodule Tldr.Source do
  @moduledoc """
  Decides what a pasted address points at: a YouTube video or a web page.

  YouTube addresses come in many shapes (`youtu.be`, shorts, live, embed,
  extra query parameters). They all become the canonical watch address,
  because that is the only form Gemini accepts as a video.
  """

  @type t :: {:youtube, String.t()} | {:web, String.t()}

  @youtube_hosts ~w(youtube.com www.youtube.com m.youtube.com music.youtube.com)
  @video_id ~r/\A[A-Za-z0-9_-]{11}\z/

  @doc """
  Splits a paste into its addresses. A single-line input drops the line
  breaks of a pasted list, so an address that starts right after another
  one is split off too.
  """
  @spec addresses(String.t()) :: [String.t()]
  def addresses(paste) when is_binary(paste) do
    paste
    |> String.split()
    |> Enum.flat_map(&String.split(&1, ~r{(?=https?://)}, trim: true))
  end

  @spec parse(String.t()) :: {:ok, t()} | {:error, :invalid_url}
  def parse(input) when is_binary(input) do
    input = String.trim(input)
    input = if input =~ ~r{\A[a-z][a-z0-9+.-]*://}i, do: input, else: "https://" <> input

    with %URI{scheme: scheme, host: host} = uri when scheme in ["http", "https"] <-
           URI.parse(input),
         true <- public_host?(host) do
      case video_id(uri) do
        nil -> {:ok, {:web, URI.to_string(uri)}}
        id -> {:ok, {:youtube, "https://www.youtube.com/watch?v=" <> id}}
      end
    else
      _ -> {:error, :invalid_url}
    end
  end

  # A host needs a dot, which leaves out "localhost" and typos like "not a url".
  defp public_host?(host) when is_binary(host),
    do: String.contains?(host, ".") and not String.contains?(host, " ")

  defp public_host?(_), do: false

  defp video_id(%URI{host: "youtu.be", path: "/" <> id}), do: valid_id(id)

  defp video_id(%URI{host: host, path: path, query: query}) when host in @youtube_hosts do
    case String.split(path || "", "/", trim: true) do
      ["watch"] -> query |> Kernel.||("") |> URI.decode_query() |> Map.get("v") |> valid_id()
      [prefix, id] when prefix in ~w(shorts live embed) -> valid_id(id)
      _ -> nil
    end
  end

  defp video_id(_uri), do: nil

  defp valid_id(id) when is_binary(id), do: if(id =~ @video_id, do: id)
  defp valid_id(_), do: nil
end
