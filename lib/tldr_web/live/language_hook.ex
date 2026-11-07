defmodule TldrWeb.LanguageHook do
  @moduledoc """
  The reader's language for every LiveView: `on_mount TldrWeb.LanguageHook`
  assigns `language` from the session and handles the `"language"` event of
  the switch in `TldrWeb.Layouts.header/1`.
  """

  import Phoenix.Component, only: [assign: 2]
  import Phoenix.LiveView, only: [attach_hook: 4]

  alias Tldr.Language

  def on_mount(:default, _params, session, socket) do
    language = Language.known(session["language"]) || Language.default()

    {:cont,
     socket
     |> assign(language: language)
     |> attach_hook(:language, :handle_event, &switch/3)}
  end

  defp switch("language", %{"language" => language}, socket),
    do: {:halt, assign(socket, language: Language.known(language) || socket.assigns.language)}

  defp switch(_event, _params, socket), do: {:cont, socket}
end
