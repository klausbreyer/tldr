defmodule Tldr.YouTube do
  @moduledoc """
  Looks up a video's title and channel through YouTube's public oEmbed endpoint.

  The model watches the video itself; this only names it. A failed lookup
  is not an error, the summary simply has no title.
  """

  @spec info(String.t()) :: %{title: String.t() | nil, channel: String.t() | nil}
  def info(watch_url) do
    options =
      [
        url: "https://www.youtube.com/oembed",
        params: [url: watch_url, format: "json"],
        receive_timeout: 5_000,
        retry: false
      ] ++ Application.get_env(:tldr, __MODULE__, [])

    case Req.get(options) do
      {:ok, %Req.Response{status: 200, body: %{} = body}} ->
        %{title: body["title"], channel: body["author_name"]}

      _ ->
        %{title: nil, channel: nil}
    end
  end
end
