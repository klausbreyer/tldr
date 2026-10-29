defmodule TldrWeb.PrefixControllerTest do
  use TldrWeb.ConnCase, async: true

  test "addresses after tldr.tf/ go to the shared form, their own queries intact", %{conn: conn} do
    conn = get(conn, "/https://a.com/x?si=1&t=2https://youtu.be/jNQXAC9IVRw")

    assert redirected_to(conn) == "/?a=https://a.com/x?si=1%26t=2+https://youtu.be/jNQXAC9IVRw"
  end

  test "repairs the double slash a proxy merged into one", %{conn: conn} do
    conn = get(conn, "/https:/a.com/x/https:/b.org")

    assert redirected_to(conn) == "/?a=https://a.com/x/+https://b.org"
  end

  test "a path that is not an address is not found", %{conn: conn} do
    assert response(get(conn, "/nothing-here"), 404)
  end
end
