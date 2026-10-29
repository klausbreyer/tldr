defmodule TldrWeb.ThumbnailController do
  @moduledoc """
  `/thumbnail/:id` passes the preview image of a YouTube video on to the
  reader. tldr fetches it from YouTube for every request and keeps nothing;
  the reader's browser caches it for a day.
  """

  use TldrWeb, :controller

  def show(conn, %{"id" => id}) do
    # Only a real video id reaches YouTube.
    with ^id <- Tldr.Source.video_id("youtu.be/" <> id),
         {:ok, jpeg} <- Tldr.YouTube.thumbnail(id) do
      conn
      |> put_resp_content_type("image/jpeg", nil)
      |> put_resp_header("cache-control", "public, max-age=86400")
      |> send_resp(200, jpeg)
    else
      _ -> send_resp(conn, 404, "")
    end
  end
end
