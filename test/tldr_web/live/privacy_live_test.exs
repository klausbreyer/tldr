defmodule TldrWeb.PrivacyLiveTest do
  use TldrWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the privacy page says that nothing is stored, in the reader's language", %{conn: conn} do
    {:ok, _view, html} =
      conn |> put_req_header("accept-language", "de") |> live(~p"/privacy")

    assert html =~ "Ich speichere deine Daten nicht."
    assert html =~ "OpenRouter"
    assert html =~ "Dein Browser spricht dabei nicht mit YouTube."
    assert html =~ "bunny.net auf Magic Containers in Frankfurt"

    {:ok, _view, html} =
      conn |> put_req_header("accept-language", "en") |> live(~p"/privacy")

    assert html =~ "I do not store your data."
    assert html =~ "Magic Containers by bunny.net in Frankfurt"
  end

  test "the footer links the privacy page, the code and the legal notice of v01.io", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, ~s(footer a[href="/privacy"]))
    assert has_element?(view, ~s(footer a[href="https://github.com/klausbreyer/tldr"]))
    assert has_element?(view, ~s(footer a[href="https://www.v01.io/pages/imprint/"]))
  end
end
