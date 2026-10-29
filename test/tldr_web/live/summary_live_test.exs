defmodule TldrWeb.SummaryLiveTest do
  use TldrWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup do
    Req.Test.stub(Tldr.Page, fn conn ->
      case conn.request_path do
        "/blocked" ->
          Plug.Conn.send_resp(conn, 403, "no")

        path ->
          conn
          |> Plug.Conn.put_resp_content_type("text/html")
          |> Plug.Conn.send_resp(200, "<title>Page #{path}</title><p>Text of #{path}</p>")
      end
    end)

    # The model answers with the page title it was given, so each summary
    # can be told apart.
    Req.Test.stub(Tldr.OpenRouter, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      [_system, %{"content" => [%{"text" => text} | _]}] = Jason.decode!(body)["messages"]
      [_, title] = Regex.run(~r/Title: (.*)/, text)
      answer = %{"tldr" => "Summary of #{title}.", "points" => ["A point.", "Another point."]}

      Req.Test.json(conn, %{"choices" => [%{"message" => %{"content" => Jason.encode!(answer)}}]})
    end)

    :ok
  end

  test "one address gets one summary in the single layout", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ ~s(data-layout="single")
    assert html =~ ~s(href="https://v01.io")
    assert has_element?(view, ~s(footer a[href="/"]), "tldr.tf")

    view |> form("#summarize", %{addresses: "https://example.com/one"}) |> render_submit()
    html = render_async(view)

    assert html =~ ~s(data-layout="single")
    assert html =~ "Page /one"
    assert html =~ "Summary of Page /one."
    assert html =~ "Another point."
  end

  test "a second summary turns the page into a list, newest first", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> form("#summarize", %{addresses: "https://example.com/one"}) |> render_submit()
    render_async(view)
    view |> form("#summarize", %{addresses: "https://example.com/two"}) |> render_submit()
    html = render_async(view)

    assert html =~ ~s(data-layout="list")
    {two, _} = :binary.match(html, "Summary of Page /two.")
    {one, _} = :binary.match(html, "Summary of Page /one.")
    assert two < one
  end

  test "several pasted addresses run at once", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#summarize", %{addresses: "https://example.com/one https://example.com/two"})
    |> render_submit()

    html = render_async(view)
    assert html =~ ~s(data-layout="list")
    assert html =~ "Summary of Page /one."
    assert html =~ "Summary of Page /two."
  end

  test "a failure is a plain sentence", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#summarize", %{addresses: "https://example.com/blocked kein-link"})
    |> render_submit()

    html = render_async(view)
    assert html =~ "The page blocks automated requests."
    assert html =~ "That is not a valid address."
  end

  test "the browser's language is the default, and the reader can switch", %{conn: conn} do
    conn = put_req_header(conn, "accept-language", "de-DE,de;q=0.9,en;q=0.8")
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ "Link einfügen"

    html = view |> element("button", "EN") |> render_click()
    assert html =~ "Paste a link"

    view |> form("#summarize", %{addresses: "kein-link"}) |> render_submit()
    assert render_async(view) =~ "That is not a valid address."
  end

  test "the language cookie beats the browser", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "en-US")
      |> put_req_cookie("tldr_language", "de")

    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Link einfügen"
  end

  test "a shared link shows the wordmark and a sentence in the reader's language", %{conn: conn} do
    html = conn |> put_req_header("accept-language", "de") |> get(~p"/") |> html_response(200)
    assert html =~ ~r{<meta property="og:image" content="http://[^/"]+/images/og.png">}
    assert html =~ ~s(<meta name="twitter:card" content="summary_large_image">)
    assert html =~ ~s(<meta property="og:description" content="Webseite oder YouTube)
  end
end
