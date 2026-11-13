defmodule TldrWeb.PrivacyLive do
  @moduledoc """
  The privacy page at `/privacy`: what happens to the reader's data. It
  speaks the reader's language, like the summary page.
  """

  use TldrWeb, :live_view

  alias TldrWeb.Words

  on_mount TldrWeb.LanguageHook

  @impl true
  def mount(_params, _session, socket) do
    language = socket.assigns.language

    {:ok, assign(socket, page_title: "#{Words.t(language, :privacy)} · tldr.tf")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <Layouts.page class="pt-6 sm:pt-8">
        <Layouts.header language={@language} />
        <h1 class="mb-6 text-[30px] leading-[1.1] font-bold tracking-tight sm:text-4xl">
          {Words.t(@language, :privacy)}
        </h1>
        <p class="mb-5 text-xl leading-7 text-balance sm:text-[22px] sm:leading-[1.35]">
          {Words.t(@language, :privacy_stored)}
        </p>
        <div class="max-w-[34rem] space-y-4 text-base leading-normal text-pretty">
          <p>{Words.t(@language, :privacy_cache)}</p>
          <p>{Words.t(@language, :privacy_models)}</p>
          <p>{Words.t(@language, :privacy_youtube)}</p>
          <p>{Words.t(@language, :privacy_hosting)}</p>
        </div>
        <:footer>
          <Layouts.footer language={@language} current={:privacy} />
        </:footer>
      </Layouts.page>
    </Layouts.app>
    """
  end
end
