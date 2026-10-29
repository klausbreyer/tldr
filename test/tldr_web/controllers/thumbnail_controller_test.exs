defmodule TldrWeb.ThumbnailControllerTest do
  use TldrWeb.ConnCase, async: true

  test "passes the preview image of a video on from YouTube", %{conn: conn} do
    Req.Test.stub(Tldr.YouTube, fn conn ->
      assert conn.host == "i.ytimg.com"
      assert conn.request_path == "/vi/jNQXAC9IVRw/mqdefault.jpg"

      conn
      |> Plug.Conn.put_resp_content_type("image/jpeg", nil)
      |> Plug.Conn.send_resp(200, "jpeg bytes")
    end)

    conn = get(conn, ~p"/thumbnail/jNQXAC9IVRw")

    assert response(conn, 200) == "jpeg bytes"
    assert get_resp_header(conn, "content-type") == ["image/jpeg"]
    assert [cache] = get_resp_header(conn, "cache-control")
    assert cache =~ "max-age"
  end

  test "a video without an image, or an id that is none, is not found", %{conn: conn} do
    Req.Test.stub(Tldr.YouTube, &Plug.Conn.send_resp(&1, 404, ""))

    assert conn |> get(~p"/thumbnail/jNQXAC9IVRw") |> response(404)
    assert conn |> get(~p"/thumbnail/not-an-id") |> response(404)
  end
end
