defmodule TldrWeb.PageController do
  use TldrWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
