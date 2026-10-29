defmodule Tldr.YouTube do
  @moduledoc """
  Looks up a video's title and channel through YouTube's public oEmbed
  endpoint, and fetches its preview image.

  The model watches the video itself; this only names and shows it. A failed
  lookup is not an error, the summary simply has no title or no image.
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

  @doc """
  The JPEG preview image of a video, 320 by 180 pixels. `id` must be a valid
  video id (`Tldr.Source.video_id/1`).
  """
  @spec thumbnail(String.t()) :: {:ok, binary()} | :error
  def thumbnail(id) do
    options =
      [
        url: "https://i.ytimg.com/vi/#{id}/mqdefault.jpg",
        decode_body: false,
        receive_timeout: 5_000,
        retry: false
      ] ++ Application.get_env(:tldr, __MODULE__, [])

    case Req.get(options) do
      {:ok, %Req.Response{status: 200, body: jpeg}} -> {:ok, jpeg}
      _ -> :error
    end
  end
end
