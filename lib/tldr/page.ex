defmodule Tldr.Page do
  @moduledoc """
  Fetches a web page and turns it into its title and readable text.

  The model gets plain text, not HTML: it is a fraction of the tokens, and
  the page chrome (navigation, footer, scripts) only distracts it.
  """

  defstruct [:title, :text]

  @type t :: %__MODULE__{title: String.t() | nil, text: String.t()}

  # Elements that never carry the content a reader came for.
  @chrome ~w(script style noscript template svg iframe nav header footer aside form button)
  # Elements that end a line of text.
  @blocks ~w(p div section article main h1 h2 h3 h4 h5 h6 li dt dd blockquote pre tr br figcaption)
  # Enough for any article; Gemini's context is far larger, the bill is not.
  @max_chars 150_000

  @spec fetch(String.t()) :: {:ok, t()} | {:error, term()}
  def fetch(url) do
    options =
      [
        url: url,
        headers: [user_agent: "Mozilla/5.0 (Macintosh) tldr", accept: "text/html"],
        receive_timeout: 15_000
      ] ++ Application.get_env(:tldr, __MODULE__, [])

    case Req.get(options) do
      {:ok, %Req.Response{status: 200} = response} ->
        if html?(response) and is_binary(response.body),
          do: {:ok, extract(response.body)},
          else: {:error, :not_html}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, exception} ->
        {:error, {:unreachable, Exception.message(exception)}}
    end
  end

  @spec extract(String.t()) :: t()
  def extract(html) do
    document = Floki.parse_document!(html)

    %__MODULE__{title: title(document), text: document |> content() |> text()}
  end

  defp html?(response) do
    response
    |> Req.Response.get_header("content-type")
    |> Enum.any?(&String.contains?(&1, "html"))
  end

  defp title(document) do
    og = document |> Floki.attribute(~s(meta[property="og:title"]), "content") |> List.first()
    tag = document |> Floki.find("title") |> Floki.text()

    Enum.find([og, tag], &(is_binary(&1) and String.trim(&1) != "")) |> then(&(&1 && squish(&1)))
  end

  # The article or main element when the page has one, the body otherwise.
  defp content(document) do
    Enum.find_value(["article", "main", "body"], document, fn selector ->
      case Floki.find(document, selector) do
        [] -> nil
        found -> found
      end
    end)
  end

  defp text(nodes) do
    nodes
    |> Floki.filter_out(Enum.join(@chrome, ", "))
    |> Floki.traverse_and_update(fn
      {tag, attrs, children} when tag in @blocks -> {tag, attrs, children ++ ["\n"]}
      node -> node
    end)
    |> Floki.text()
    |> String.split("\n")
    |> Enum.map(&squish/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
    |> String.slice(0, @max_chars)
  end

  defp squish(string), do: string |> String.split() |> Enum.join(" ")
end
