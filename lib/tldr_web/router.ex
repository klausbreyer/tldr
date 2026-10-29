defmodule TldrWeb.Router do
  use TldrWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TldrWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_language
  end

  scope "/", TldrWeb do
    pipe_through :browser

    live "/", SummaryLive
    live "/privacy", PrivacyLive
  end

  # The reader's language: the cookie the language switch sets, else the
  # browser's, else English. The LiveView reads it from the session.
  defp put_language(conn, _opts) do
    conn = fetch_cookies(conn)

    language =
      Tldr.Language.known(conn.cookies["tldr_language"]) ||
        Tldr.Language.from_accept_language(
          conn
          |> get_req_header("accept-language")
          |> List.first()
        )

    conn |> assign(:language, language) |> put_session(:language, language)
  end
end
