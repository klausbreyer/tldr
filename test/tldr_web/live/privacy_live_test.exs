defmodule TldrWeb.PrivacyLiveTest do
  use TldrWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the privacy page says what is stored and where, in the reader's language", %{
    conn: conn
  } do
    {:ok, _view, html} =
      conn |> put_req_header("accept-language", "de") |> live(~p"/privacy")

    assert html =~ "Ich speichere nichts über dich."
    assert html =~ "24 Stunden lang in einer Postgres-Datenbank bei Hetzner"
    assert html =~ "OpenRouter"
    assert html =~ "Dein Browser spricht dabei nicht mit YouTube."
    assert html =~ "bunny.net auf Magic Containers in Frankfurt"

    {:ok, _view, html} =
      conn |> put_req_header("accept-language", "en") |> live(~p"/privacy")

    assert html =~ "I store nothing about you."
    assert html =~ "24 hours in a Postgres database at Hetzner"
    assert html =~ "Magic Containers by bunny.net in Frankfurt"
  end

  test "the language switch works on the privacy and shortcut pages", %{conn: conn} do
    for path <- [~p"/privacy", ~p"/shortcut"] do
      {:ok, view, _html} =
        conn |> put_req_header("accept-language", "en") |> live(path)

      assert view |> element("button", "DE") |> render_click() =~ "Datenschutz"
    end
  end

  test "the footer links the privacy page and the code", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, ~s(footer a[href="/privacy"]))
    assert has_element?(view, ~s(footer a[href="https://github.com/klausbreyer/tldr"]))
  end
end
