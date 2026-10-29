defmodule TldrWeb.PrefixController do
  @moduledoc """
  `tldr.tf/<address>`: put tldr.tf/ in front of a link, or of several links
  in a row, and get their summaries (`docs/decisions/011`).

  Everything after the first slash is the paste, its query string included,
  so the query of an address stays its own. It goes on to the shared form
  `/?a=...`, the one form the address bar shows. A path that does not start
  with an address is not found.
  """

  use TldrWeb, :controller

  alias Tldr.Source

  def show(conn, _params) do
    "/" <> paste = conn.request_path

    paste =
      if conn.query_string == "", do: paste, else: paste <> "?" <> conn.query_string

    # Some proxies merge `//` into `/`.
    paste = String.replace(paste, ~r{(https?:)/(?!/)}, "\\1//")

    if paste =~ ~r{\Ahttps?://} do
      redirect(conn, to: TldrWeb.SummaryLive.share_path(Source.addresses(paste)))
    else
      raise Phoenix.Router.NoRouteError, conn: conn, router: TldrWeb.Router
    end
  end
end
