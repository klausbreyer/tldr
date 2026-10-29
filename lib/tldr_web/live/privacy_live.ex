defmodule TldrWeb.PrivacyLive do
  @moduledoc """
  The privacy page at `/privacy`: what happens to the reader's data. It
  speaks the reader's language, like the summary page.
  """

  use TldrWeb, :live_view

  alias Tldr.Language
  alias TldrWeb.Words

  @impl true
  def mount(_params, session, socket) do
    language = Language.known(session["language"]) || Language.default()

    {:ok,
     assign(socket, page_title: "#{Words.t(language, :privacy)} · tldr.tf", language: language)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto flex min-h-dvh max-w-[680px] flex-col px-5 pt-5 sm:pt-[15vh]">
        <div class="flex-1 pb-16">
          <a href="/" class="hover:opacity-80">
            <Layouts.wordmark class="mb-8 block text-5xl sm:text-6xl" />
          </a>
          <h1 class="mb-4 text-xl font-medium sm:text-[22px]">{Words.t(@language, :privacy)}</h1>
          <div class="space-y-3 text-text">
            <p>{Words.t(@language, :privacy_stored)}</p>
            <p>{Words.t(@language, :privacy_models)}</p>
            <p>{Words.t(@language, :privacy_youtube)}</p>
            <p>{Words.t(@language, :privacy_hosting)}</p>
          </div>
        </div>

        <Layouts.footer language={@language} />
      </div>
    </Layouts.app>
    """
  end
end
