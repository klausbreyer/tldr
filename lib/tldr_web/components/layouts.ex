defmodule TldrWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use TldrWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Wraps every page. The page brings its own layout; this adds the flash.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main>
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  The column every page lives in: one width and one left edge for every
  state, so nothing jumps sideways when a summary arrives. The footer sits
  at the bottom of the screen on a short page.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :footer, required: true

  def page(assigns) do
    ~H"""
    <div class={["mx-auto flex min-h-dvh max-w-[640px] flex-col px-5 sm:px-6", @class]} {@rest}>
      <div class="flex-1 pb-16">{render_slot(@inner_block)}</div>
      {render_slot(@footer)}
    </div>
    """
  end

  @doc """
  The header of every page and every state: the wordmark and the language
  switch, the same size and place everywhere.

  `home` says what the wordmark does: `:none` on the summary page, where
  going home would empty the list, `:site` in the side panel, where it opens
  tldr.tf in a new tab, and `:link` on the other pages.
  """
  attr :language, :string, required: true
  attr :home, :atom, values: [:none, :site, :link], default: :link

  def header(assigns) do
    ~H"""
    <header class="mb-8 flex items-baseline justify-between gap-4 sm:mb-10">
      <.wordmark :if={@home == :none} class="text-[30px]" />
      <a
        :if={@home == :site}
        id="panel-home"
        href="https://tldr.tf"
        target="_blank"
        rel="noopener"
        class="hover:opacity-80"
      >
        <.wordmark class="text-[30px]" />
      </a>
      <a :if={@home == :link} href="/" class="hover:opacity-80">
        <.wordmark class="text-[30px]" />
      </a>
      <div
        role="group"
        aria-label={TldrWeb.Words.t(@language, :language)}
        class="-mr-3 flex shrink-0 text-sm tracking-wide"
      >
        <button
          :for={language <- Tldr.Language.all()}
          type="button"
          aria-pressed={to_string(language == @language)}
          phx-click={
            JS.push("language", value: %{language: language})
            |> JS.dispatch("tldr:language", detail: %{language: language})
          }
          class={[
            "-my-3 cursor-pointer px-3 py-3 underline-offset-4",
            if(language == @language,
              do: "text-brand",
              else: "hover:text-brand"
            )
          ]}
        >
          {String.upcase(language)}
        </button>
      </div>
    </header>
    """
  end

  @doc """
  The footer of every page: one quiet row of links, who made it at the end.
  A phone cannot install the Chrome extension, so it does not see the link.
  """
  attr :language, :string, required: true
  attr :embedded, :boolean, default: false
  attr :current, :atom, default: nil, doc: "the page showing now, `:privacy` or `:shortcut`"

  def footer(assigns) do
    assigns =
      assign(assigns,
        year: Date.utc_today().year,
        site: if(assigns.embedded, do: "https://tldr.tf", else: ""),
        target: if(assigns.embedded, do: "_blank")
      )

    ~H"""
    <footer class="flex flex-wrap items-baseline gap-x-5 gap-y-4 border-t border-line pt-6 pb-8 text-sm">
      <a
        href="https://chromewebstore.google.com/detail/jnhafnmghjfpcbmijehgdoiekilggkdj"
        target="_blank"
        rel="noopener"
        class="-my-3 hidden py-3 hover:text-brand sm:inline"
      >
        {TldrWeb.Words.t(@language, :chrome_extension)}
      </a>
      <a
        href={@site <> ~p"/shortcut"}
        target={@target}
        rel="noopener"
        class={["-my-3 py-3 hover:text-brand", @current == :shortcut && "text-brand"]}
      >
        {TldrWeb.Words.t(@language, :shortcut)}
      </a>
      <a
        href={@site <> ~p"/privacy"}
        target={@target}
        rel="noopener"
        class={["-my-3 py-3 hover:text-brand", @current == :privacy && "text-brand"]}
      >
        {TldrWeb.Words.t(@language, :privacy)}
      </a>
      <a
        href="https://github.com/klausbreyer/tldr"
        target="_blank"
        rel="noopener"
        class="-my-3 py-3 hover:text-brand"
      >
        {TldrWeb.Words.t(@language, :open_source)}
      </a>
      <span class="w-full text-[13px] sm:ml-auto sm:w-auto">
        &copy; {@year}
        <a href="https://v01.io" target="_blank" rel="noopener" class="hover:text-brand">
          Klaus Breyer
        </a>
      </span>
    </footer>
    """
  end

  @doc """
  The logo: "tldr" in the accent, ".tf" in the text color. The one at the
  top of the summary page is not a link, because going home would empty
  the list. In the side panel, it opens the website in a new tab.
  """
  attr :class, :string, default: nil

  def wordmark(assigns) do
    ~H"""
    <span class={["font-wordmark leading-none font-bold", @class]}>
      <span class="text-brand">tldr</span><span class="text-text">.tf</span>
    </span>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="Keine Verbindung"
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Verbinde neu …
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Der Server antwortet nicht"
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Verbinde neu …
      </.flash>
    </div>
    """
  end
end
