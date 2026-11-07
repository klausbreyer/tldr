defmodule TldrWeb.ShortcutLive do
  @moduledoc "Instructions for the Apple shortcut, in the reader's language."

  use TldrWeb, :live_view

  alias TldrWeb.Words

  on_mount TldrWeb.LanguageHook

  @share ~s(<span class="hero-arrow-up-on-square inline-block size-[1.1em] -mr-0.5 align-[-0.15em]" aria-hidden="true"></span>)

  @impl true
  def mount(_params, _session, socket) do
    language = socket.assigns.language

    {:ok, assign(socket, page_title: "#{Words.t(language, :shortcut)} · tldr.tf")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <Layouts.page class="pt-6 sm:pt-8">
        <Layouts.header language={@language} />
        <h1 class="mb-6 text-[30px] leading-[1.1] font-bold tracking-tight sm:text-4xl">
          {Words.t(@language, :shortcut)}
        </h1>
        <p class="mb-6 text-xl leading-7 sm:text-[22px] sm:leading-[1.35]">
          <span
            :for={sentence <- Words.sentences(Words.t(@language, :shortcut_intro))}
            class="block"
          >
            {sentence}
          </span>
        </p>
        <a
          href="https://www.icloud.com/shortcuts/0e2631559fa8434aab1c95af874f6029"
          target="_blank"
          rel="noopener"
          class="flex h-12 w-full items-center justify-center bg-brand px-6 sm:inline-flex sm:w-auto text-base leading-none font-medium text-white hover:bg-rose-700"
        >
          {Words.t(@language, :shortcut_download)}
        </a>
        <p class="mt-3 max-w-[34rem] text-base leading-normal text-pretty">
          <span
            :for={sentence <- Words.sentences(Words.t(@language, :shortcut_install))}
            class="block"
          >
            {names(sentence)}
          </span>
        </p>

        <section id="shortcut-ios" class="mt-8">
          <h2 class="mb-3 text-xl font-semibold sm:mb-4">{Words.t(@language, :shortcut_ios)}</h2>
          <ol class="max-w-[34rem] space-y-3 text-base leading-normal text-pretty">
            <li class="relative pl-5">
              <span class="absolute left-0 tabular-nums" aria-hidden="true">1.</span>{names(
                Words.t(@language, :shortcut_ios_share)
              )}
            </li>
            <li class="relative pl-5">
              <span class="absolute left-0 tabular-nums" aria-hidden="true">2.</span>{names(
                Words.t(@language, :shortcut_ios_run)
              )}
            </li>
          </ol>
          <p class="mt-5 max-w-[30rem] text-[13px] leading-5 text-pretty">
            {names(Words.t(@language, :shortcut_ios_hint))}
          </p>
        </section>

        <section id="shortcut-mac" class="mt-8">
          <h2 class="mb-3 text-xl font-semibold sm:mb-4">{Words.t(@language, :shortcut_mac)}</h2>
          <ol class="max-w-[34rem] space-y-3 text-base leading-normal text-pretty">
            <li class="relative pl-5">
              <span class="absolute left-0 tabular-nums" aria-hidden="true">1.</span>{names(
                Words.t(@language, :shortcut_mac_share)
              )}
            </li>
            <li class="relative pl-5">
              <span class="absolute left-0 tabular-nums" aria-hidden="true">2.</span>{names(
                Words.t(@language, :shortcut_mac_run)
              )}
            </li>
          </ol>
          <p class="mt-5 max-w-[30rem] text-[13px] leading-5 text-pretty">
            {names(Words.t(@language, :shortcut_mac_hint))}
          </p>
        </section>
        <:footer>
          <Layouts.footer language={@language} current={:shortcut} />
        </:footer>
      </Layouts.page>
    </Layouts.app>
    """
  end

  # The names of buttons and menus stand in quotes in `TldrWeb.Words`
  # („Teilen“, “Share”). Here they lose the quotes and stand out by weight.
  # `%{share}` becomes Apple's Share symbol.
  defp names(text) do
    ~r/[„“]([^“”]+)[“”]/u
    |> Regex.split(text, include_captures: true)
    |> Enum.map_join(fn part ->
      case Regex.run(~r/\A[„“]([^“”]+)[“”]\z/u, part) do
        [_, name] -> ~s(<strong class="font-semibold">) <> escape(name) <> "</strong>"
        nil -> part |> escape() |> String.replace("%{share}", @share)
      end
    end)
    |> raw()
  end

  defp escape(text), do: text |> html_escape() |> safe_to_string()
end
