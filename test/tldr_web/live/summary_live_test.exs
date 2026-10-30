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

      [_system, %{"content" => [_instruction, %{"text" => data} | _]}] =
        Jason.decode!(body)["messages"]

      title = Jason.decode!(data)["title"]
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

  test "the side panel hides the form and opens navigation outside the panel", %{conn: conn} do
    conn = put_req_header(conn, "sec-fetch-dest", "iframe")
    {:ok, view, html} = live(conn, "/https://example.com/one")

    refute html =~ ~s(id="summarize")
    refute has_element?(view, "#summarize")

    assert has_element?(
             view,
             ~s(a#panel-home[href="https://tldr.tf"][target="_blank"]),
             "tldr.tf"
           )

    assert has_element?(view, ~s(footer a[href="https://tldr.tf/shortcut"][target="_blank"]))
    assert has_element?(view, ~s(footer a[href="https://tldr.tf/privacy"][target="_blank"]))
    refute has_element?(view, "footer a:not([target='_blank'])")
    assert render_async(view) =~ "Summary of Page /one."
    assert view |> element("button", "DE") |> render_click() =~ "Kopieren"
    refute has_element?(view, "#summarize")
  end

  test "the empty side panel has no paste hint", %{conn: conn} do
    {:ok, view, html} = conn |> put_req_header("sec-fetch-dest", "iframe") |> live("/")
    refute has_element?(view, "#summarize")
    refute html =~ TldrWeb.Words.t("en", :hint)
    assert has_element?(view, "#panel-home")
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

  test "the addresses go into the address bar, so the page can be shared", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#summarize", %{addresses: "https://example.com/one?x=1&y=2#part"})
    |> render_submit()

    assert_patch(view, "/https://example.com/one?x=1&y=2")

    view |> form("#summarize", %{addresses: "example.com/two"}) |> render_submit()
    assert_patch(view, "/https://example.com/twohttps://example.com/one?x=1&y=2")
  end

  test "a shared address summarizes its addresses again, in the same order", %{conn: conn} do
    {:ok, view, html} = live(conn, "/https://example.com/twohttps://example.com/one?x=1&y=2")
    assert html =~ "https://example.com/two"
    assert html =~ "https://example.com/one?x=1&amp;y=2"

    html = render_async(view)
    {two, _} = :binary.match(html, "Summary of Page /two.")
    {one, _} = :binary.match(html, "Summary of Page /one.")
    assert two < one
  end

  test "a shared address survives a proxy that merges its double slashes", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/https:/example.com/one")
    assert render_async(view) =~ "Summary of Page /one."
  end

  test "a path that is not an address is not found", %{conn: conn} do
    assert_error_sent 404, fn -> get(conn, "/nothing-here") end
  end

  test "a video shows its preview image through tldr, a page none", %{conn: conn} do
    Req.Test.stub(Tldr.YouTube, &Req.Test.json(&1, %{"title" => "A talk"}))
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#summarize", %{addresses: "youtu.be/jNQXAC9IVRw?si=x https://example.com/one"})
    |> render_submit()

    assert_patch(view, "/https://www.youtube.com/watch?v=jNQXAC9IVRwhttps://example.com/one")

    # The image is there while the video is still being watched.
    assert has_element?(view, ~s(img[src="/thumbnail/jNQXAC9IVRw"]))
    render_async(view)
    assert has_element?(view, ~s(img[src="/thumbnail/jNQXAC9IVRw"]))
    assert [_one] = view |> render() |> Floki.parse_document!() |> Floki.find("img")
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

  test "an invalid model answer shows an error in both languages", %{conn: conn} do
    Req.Test.stub(Tldr.OpenRouter, fn conn ->
      answer = %{"tldr" => "Text", "points" => [%{"unexpected" => "object"}]}
      Req.Test.json(conn, %{"choices" => [%{"message" => %{"content" => Jason.encode!(answer)}}]})
    end)

    for language <- ["de", "en"] do
      {:ok, view, _html} = conn |> put_req_header("accept-language", language) |> live(~p"/")
      view |> form("#summarize", %{addresses: "https://example.com"}) |> render_submit()
      render_async(view)

      assert has_element?(view, "#summaries", TldrWeb.Words.t(language, :invalid_answer))
      refute has_element?(view, "#summaries ul")
    end
  end

  test "a slow video stays in the waiting state until its summary arrives", %{conn: conn} do
    test = self()

    Req.Test.stub(
      Tldr.YouTube,
      &Req.Test.json(&1, %{"title" => "A video", "author_name" => "A channel"})
    )

    Req.Test.stub(Tldr.OpenRouter, fn conn ->
      send(test, {:video_waiting, self()})

      receive do
        :finish_video ->
          answer = %{"tldr" => "The video summary.", "points" => []}

          Req.Test.json(conn, %{
            "choices" => [%{"message" => %{"content" => Jason.encode!(answer)}}]
          })
      end
    end)

    {:ok, view, _html} = live(conn, ~p"/")
    view |> form("#summarize", %{addresses: "https://youtu.be/jNQXAC9IVRw"}) |> render_submit()
    assert_receive {:video_waiting, task}, 1_000
    assert has_element?(view, "#summaries", "Watching the video")
    assert has_element?(view, "#summaries .tldr-pulse")

    send(task, :finish_video)
    render_async(view)
    assert has_element?(view, "#summaries", "The video summary.")
    refute has_element?(view, "#summaries .tldr-pulse")
  end

  test "a shared link shows the wordmark and the words in the reader's language", %{conn: conn} do
    html = conn |> put_req_header("accept-language", "de") |> get(~p"/") |> html_response(200)
    assert html =~ ~r{<meta property="og:image" content="http://[^/"]+/images/og.png">}
    assert html =~ ~s(<meta name="twitter:card" content="summary_large_image">)

    assert html =~
             ~s(<meta property="og:title" content="tldr.tf, eine Zusammenfassung für jeden Link">)

    assert html =~ ~s(<meta property="og:description" content="Webseite oder YouTube)
  end
end
