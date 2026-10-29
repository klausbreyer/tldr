defmodule TldrWeb.Router do
  use TldrWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TldrWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :browser_headers
    plug :put_language
  end

  # Allow only the configured Chrome extension to show tldr in its side panel.
  defp browser_headers(conn, _opts) do
    ancestors =
      case Application.get_env(:tldr, :chrome_extension_id) do
        nil -> "'self'"
        id -> "'self' chrome-extension://#{id}"
      end

    put_secure_browser_headers(conn, %{
      "content-security-policy" => "base-uri 'self'; frame-ancestors #{ancestors};"
    })
  end

  # Video preview images come through tldr, so the reader's browser never
  # talks to YouTube.
  scope "/", TldrWeb do
    get "/thumbnail/:id", ThumbnailController, :show
  end

  scope "/", TldrWeb do
    pipe_through :browser

    live "/privacy", PrivacyLive
    live "/shortcut", ShortcutLive
    # Last: every other path is the page, its addresses after the host.
    live "/*path", SummaryLive
  end

  # The reader's language: the cookie the language switch sets, else the
  # browser's, else English. The LiveView reads it from the session.
  defp put_language(conn, _opts) do
    conn = fetch_cookies(conn)

    cookie =
      if get_req_header(conn, "sec-fetch-dest") == ["iframe"],
        do: "tldr_embed_language",
        else: "tldr_language"

    language =
      Tldr.Language.known(conn.cookies[cookie]) ||
        Tldr.Language.from_accept_language(
          conn
          |> get_req_header("accept-language")
          |> List.first()
        )

    conn |> assign(:language, language) |> put_session(:language, language)
  end
end
