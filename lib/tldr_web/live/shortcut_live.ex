defmodule TldrWeb.ShortcutLive do
  @moduledoc "Instructions for the Apple shortcut, in the reader's language."

  use TldrWeb, :live_view

  alias Tldr.Language
  alias TldrWeb.Words

  @impl true
  def mount(_params, session, socket) do
    language = Language.known(session["language"]) || Language.default()

    {:ok,
     assign(socket, page_title: "#{Words.t(language, :shortcut)} · tldr.tf", language: language)}
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
          <h1 class="mb-4 text-xl font-medium sm:text-[22px]">{Words.t(@language, :shortcut)}</h1>
          <p class="mb-4">{Words.t(@language, :shortcut_intro)}</p>
          <a
            href="https://www.icloud.com/shortcuts/0e2631559fa8434aab1c95af874f6029"
            target="_blank"
            rel="noopener"
            class="text-brand underline underline-offset-4 hover:opacity-80"
          >
            {Words.t(@language, :shortcut_download)}
          </a>
          <p class="mt-3">{Words.t(@language, :shortcut_install)}</p>

          <section id="shortcut-ios" class="mt-8">
            <h2 class="mb-3 text-lg font-medium">{Words.t(@language, :shortcut_ios)}</h2>
            <ol class="list-decimal space-y-3 pl-5">
              <li>{Words.t(@language, :shortcut_ios_share)}</li>
              <li>{Words.t(@language, :shortcut_ios_run)}</li>
            </ol>
          </section>

          <section id="shortcut-mac" class="mt-8">
            <h2 class="mb-3 text-lg font-medium">{Words.t(@language, :shortcut_mac)}</h2>
            <ol class="list-decimal space-y-3 pl-5">
              <li>{Words.t(@language, :shortcut_mac_share)}</li>
              <li>{Words.t(@language, :shortcut_mac_run)}</li>
            </ol>
            <p class="mt-4">{Words.t(@language, :shortcut_mac_hint)}</p>
          </section>
        </div>

        <Layouts.footer language={@language} />
      </div>
    </Layouts.app>
    """
  end
end
