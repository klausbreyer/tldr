defmodule TldrWeb.EmbeddingTest do
  use TldrWeb.ConnCase, async: false

  setup do
    previous = Application.get_env(:tldr, :chrome_extension_id)
    on_exit(fn -> Application.put_env(:tldr, :chrome_extension_id, previous) end)
    :ok
  end

  test "only the configured extension can embed the page", %{conn: conn} do
    id = String.duplicate("a", 32)
    Application.put_env(:tldr, :chrome_extension_id, id)
    conn = get(conn, "/")

    assert get_resp_header(conn, "content-security-policy") ==
             ["base-uri 'self'; frame-ancestors 'self' chrome-extension://#{id};"]

    assert get_resp_header(conn, "x-content-type-options") == ["nosniff"]
  end

  test "no extension is allowed by default", %{conn: conn} do
    Application.delete_env(:tldr, :chrome_extension_id)
    conn = get(conn, "/")

    assert get_resp_header(conn, "content-security-policy") ==
             ["base-uri 'self'; frame-ancestors 'self';"]
  end

  test "iframe sessions use a separate secure, partitioned cookie", %{conn: conn} do
    conn = conn |> put_req_header("sec-fetch-dest", "iframe") |> get("/")
    cookie = conn.resp_cookies["_tldr_embed_key"]
    assert cookie.same_site == "None"
    assert cookie.secure
    assert Enum.any?(get_resp_header(conn, "set-cookie"), &String.contains?(&1, "HttpOnly"))
    assert cookie.extra == "Partitioned"
    refute Map.has_key?(conn.resp_cookies, "_tldr_key")
  end

  test "standalone sessions keep their existing cookie", %{conn: conn} do
    conn = get(conn, "/")
    assert conn.resp_cookies["_tldr_key"].same_site == "Lax"
    refute Map.has_key?(conn.resp_cookies, "_tldr_embed_key")
  end

  test "iframe language is separate from the website preference", %{conn: conn} do
    conn =
      conn
      |> put_req_header("sec-fetch-dest", "iframe")
      |> put_req_cookie("tldr_language", "en")
      |> put_req_cookie("tldr_embed_language", "de")
      |> get("/")

    assert get_session(conn, :language) == "de"
  end
end
