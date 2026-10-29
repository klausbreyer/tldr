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
  The footer of every page. Like the one of texttile.blog: the product on
  the left, who made it on the right.
  """
  attr :language, :string, required: true

  def footer(assigns) do
    assigns = assign(assigns, year: Date.utc_today().year)

    ~H"""
    <footer class="flex flex-wrap items-baseline gap-x-4 gap-y-1.5 border-t border-line pt-4 pb-7 text-sm">
      <a href="/" class="hover:opacity-80"><.wordmark /></a>
      <span class="flex-1"></span>
      <a href={~p"/privacy"} class="hover:text-brand">{TldrWeb.Words.t(@language, :privacy)}</a>
      <a
        href="https://www.v01.io/pages/imprint/"
        target="_blank"
        rel="noopener"
        class="hover:text-brand"
      >
        {TldrWeb.Words.t(@language, :legal_notice)}
      </a>
      <span>
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
  top of the summary page is not a link, because a reload would empty the
  list; the footer links it home.
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
