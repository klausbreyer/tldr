defmodule TldrWeb.HealthTest do
  use TldrWeb.ConnCase, async: true

  test "GET /healthz answers ok and is never cached", %{conn: conn} do
    conn = get(conn, "/healthz")

    assert response(conn, 200) == "ok"
    assert get_resp_header(conn, "cache-control") == ["no-store"]
  end
end
