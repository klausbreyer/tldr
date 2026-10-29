defmodule Tldr.Language do
  @moduledoc """
  The languages tldr speaks, in the interface and in summaries.

  A language is its two-letter code. The reader's choice comes from the
  `tldr_language` cookie, else from the browser, else English.
  """

  @names %{"de" => "German", "en" => "English"}
  @default "en"

  @doc "Every known language code, in the order the interface lists them."
  def all, do: ~w(de en)

  def default, do: @default

  @doc "The English name of a language, for the prompt."
  def name(code), do: Map.fetch!(@names, code)

  @doc "`code` when tldr knows it, `nil` otherwise."
  def known(code) when is_map_key(@names, code), do: code
  def known(_code), do: nil

  @doc """
  The first known language in an `Accept-Language` header, by quality.
  English when the header names none.
  """
  def from_accept_language(header) when is_binary(header) do
    header
    |> String.split(",", trim: true)
    |> Enum.map(&parse_range/1)
    |> Enum.sort_by(fn {_code, quality} -> quality end, :desc)
    |> Enum.find_value(@default, fn {code, _quality} -> known(code) end)
  end

  def from_accept_language(_header), do: @default

  # "de-DE;q=0.8" becomes {"de", 0.8}.
  defp parse_range(range) do
    [tag | params] = range |> String.trim() |> String.split(";")
    code = tag |> String.split("-") |> hd() |> String.downcase()

    quality =
      Enum.find_value(params, 1.0, fn param ->
        case String.split(String.trim(param), "=") do
          ["q", value] -> parse_quality(value)
          _ -> nil
        end
      end)

    {code, quality}
  end

  defp parse_quality(value) do
    case Float.parse(value) do
      {quality, _} -> quality
      :error -> 0.0
    end
  end
end
