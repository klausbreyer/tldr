defmodule TldrWeb.ShortcutLiveTest do
  use TldrWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the footer leads to shortcut instructions in the reader's language", %{conn: conn} do
    for {language, download} <- [{"de", "Kurzbefehl hinzufügen"}, {"en", "Add Shortcut"}] do
      conn = put_req_header(conn, "accept-language", language)
      {:ok, home, _html} = live(conn, ~p"/")
      assert has_element?(home, ~s(footer a[href="/shortcut"]), "Shortcut")

      {:ok, page, _html} = live(conn, "/shortcut")
      assert has_element?(page, "h1", "Shortcut")
      assert has_element?(page, "#shortcut-ios h2", "iOS")
      assert has_element?(page, "#shortcut-mac h2", "macOS")

      assert has_element?(
               page,
               ~s(a[href="https://www.icloud.com/shortcuts/0e2631559fa8434aab1c95af874f6029"]),
               download
             )
    end
  end
end
