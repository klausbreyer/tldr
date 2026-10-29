defmodule Tldr.PageTest do
  use ExUnit.Case, async: true

  alias Tldr.Page

  @html """
  <html>
    <head>
      <title>Fallback title | Site</title>
      <meta property="og:title" content="The real title">
      <style>body { color: red }</style>
      <script>trackEverything()</script>
    </head>
    <body>
      <header><nav><a href="/">Home</a> <a href="/about">About</a></nav></header>
      <main>
        <h1>The real title</h1>
        <p>First paragraph with <b>bold</b> words.</p>
        <p>Second   paragraph.</p>
        <ul><li>One</li><li>Two</li></ul>
      </main>
      <footer>Copyright and cookie banner</footer>
    </body>
  </html>
  """

  test "extracts the title and the readable text, without page chrome" do
    page = Page.extract(@html)

    assert page.title == "The real title"

    assert page.text ==
             "The real title\nFirst paragraph with bold words.\nSecond paragraph.\nOne\nTwo"
  end

  test "falls back to the title tag and the body" do
    page =
      Page.extract("<title>Just a title</title><body><div>Hello</div><div>World</div></body>")

    assert page.title == "Just a title"
    assert page.text == "Hello\nWorld"
  end

  test "fetches an HTML page" do
    Req.Test.stub(Tldr.Page, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, @html)
    end)

    assert {:ok, %Page{title: "The real title"}} = Page.fetch("https://example.com/a")
  end

  test "refuses a page that is not HTML or does not answer" do
    Req.Test.stub(Tldr.Page, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/pdf")
      |> Plug.Conn.send_resp(200, "%PDF")
    end)

    assert Page.fetch("https://example.com/a.pdf") == {:error, :not_html}

    Req.Test.stub(Tldr.Page, &Plug.Conn.send_resp(&1, 404, "gone"))
    assert Page.fetch("https://example.com/gone") == {:error, {:http_status, 404}}
  end
end
