defmodule TldrWeb.SummaryLive do
  @moduledoc """
  The one page: an input for addresses and their summaries.

  One summary gets the calm single layout. From the second one on the page
  becomes a list, newest first. Every address runs in its own async task,
  so several run at once. The list lives in this process only: a reload
  empties it (`docs/decisions/007`).
  """

  use TldrWeb, :live_view

  alias Tldr.{Language, Source, Summarizer}
  alias TldrWeb.Words

  @impl true
  def mount(_params, session, socket) do
    language = Language.known(session["language"]) || Language.default()
    {:ok, assign(socket, page_title: "tldr.tf", items: [], submits: 0, language: language)}
  end

  # Switches the words and the language of the next summaries. The ones
  # already there stay as they are; summarizing them again would cost money.
  @impl true
  def handle_event("language", %{"language" => language}, socket) do
    {:noreply, assign(socket, language: Language.known(language) || socket.assigns.language)}
  end

  @impl true
  def handle_event("summarize", %{"addresses" => paste}, socket) do
    new_items = Enum.map(Source.addresses(paste), &new_item/1)
    opts = [language: socket.assigns.language]

    socket =
      Enum.reduce(new_items, socket, fn item, socket ->
        start_async(socket, {:summary, item.id}, fn ->
          Summarizer.summarize(item.address, opts)
        end)
      end)

    # A new input id renders a fresh, empty, focused input after every submit.
    {:noreply,
     assign(socket, items: new_items ++ socket.assigns.items, submits: socket.assigns.submits + 1)}
  end

  @impl true
  def handle_async({:summary, id}, result, socket) do
    outcome =
      case result do
        {:ok, {:ok, summary}} -> %{status: :done, summary: summary}
        {:ok, {:error, reason}} -> %{status: :error, error: reason}
        {:exit, _reason} -> %{status: :error, error: :crashed}
      end

    items =
      Enum.map(socket.assigns.items, fn
        %{id: ^id} = item -> Map.merge(item, Map.put(outcome, :seconds, seconds_since(item)))
        item -> item
      end)

    {:noreply, assign(socket, items: items)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, single: length(assigns.items) <= 1)

    ~H"""
    <Layouts.app flash={@flash}>
      <div
        data-layout={if @single, do: "single", else: "list"}
        class={[
          "mx-auto flex min-h-dvh flex-col px-5",
          if(@single,
            do: "max-w-[680px] pt-5 sm:pt-[15vh]",
            else: "max-w-[860px] pt-5 sm:pt-6"
          )
        ]}
      >
        <div class="flex-1 pb-16">
          <.wordmark :if={@single} class="mb-8 block text-5xl sm:text-6xl" />

          <.form
            for={%{}}
            id="summarize"
            phx-submit="summarize"
            class={[
              "flex items-center gap-3",
              if(@single,
                do: "border-b border-line py-2.5 text-lg sm:text-xl",
                else: "border-b border-text pt-2 pb-2.5 text-[15px]"
              )
            ]}
          >
            <span :if={@single} class="text-text" aria-hidden="true">→</span>
            <.wordmark :if={!@single} class="text-[19px]" />
            <input
              type="text"
              id={"addresses-#{@submits}"}
              name="addresses"
              aria-label="Link"
              placeholder={Words.t(@language, if(@single, do: :placeholder, else: :placeholder_more))}
              autocomplete="off"
              spellcheck="false"
              data-1p-ignore
              data-lpignore="true"
              phx-mounted={JS.focus()}
              class="min-w-0 flex-1 bg-transparent text-text placeholder:text-text/50 outline-none"
            />
            <button
              type="submit"
              class={[
                "shrink-0 cursor-pointer bg-brand text-white hover:bg-rose-700",
                if(@single, do: "px-3.5 py-1.5 text-sm", else: "px-2.5 py-0.5 text-[13px]")
              ]}
            >
              {Words.t(@language, :submit)}
            </button>
            <.languages :if={!@single} language={@language} />
          </.form>

          <div :if={@single} class="mt-4 flex items-baseline gap-4 text-sm text-text">
            <p class="flex-1">{if @items == [], do: Words.t(@language, :hint)}</p>
            <.languages language={@language} />
          </div>

          <div id="summaries">
            <.item :for={item <- @items} item={item} single={@single} language={@language} />
          </div>
        </div>

        <.footer />
      </div>
    </Layouts.app>
    """
  end

  # Like the footer of texttile.blog: the product on the left, who made it
  # on the right.
  defp footer(assigns) do
    assigns = assign(assigns, year: Date.utc_today().year)

    ~H"""
    <footer class="flex flex-wrap items-baseline gap-x-4 gap-y-1.5 border-t border-line pt-4 pb-7 text-sm">
      <a href="/" class="hover:opacity-80"><.wordmark /></a>
      <span class="flex-1"></span>
      <span>
        &copy; {@year}
        <a href="https://v01.io" target="_blank" rel="noopener" class="hover:text-brand">
          Klaus Breyer
        </a>
      </span>
    </footer>
    """
  end

  attr :class, :string, default: nil

  # The logo: "tldr" in the accent, ".tf" in the text color. The one at the
  # top is not a link, because a reload would empty the list; the footer
  # links it home.
  defp wordmark(assigns) do
    ~H"""
    <span class={["font-wordmark leading-none font-bold", @class]}>
      <span class="text-brand">tldr</span><span class="text-text">.tf</span>
    </span>
    """
  end

  attr :language, :string, required: true

  # The language switch: one button per language, the current one in the accent.
  defp languages(assigns) do
    ~H"""
    <div
      role="group"
      aria-label={Words.t(@language, :language)}
      class="-my-2 flex shrink-0 font-mono text-xs"
    >
      <button
        :for={language <- Language.all()}
        type="button"
        aria-pressed={to_string(language == @language)}
        phx-click={
          JS.push("language", value: %{language: language})
          |> JS.dispatch("tldr:language", detail: %{language: language})
        }
        class={[
          "cursor-pointer px-1.5 py-2",
          if(language == @language,
            do: "text-brand",
            else: "text-text hover:text-brand"
          )
        ]}
      >
        {String.upcase(language)}
      </button>
    </div>
    """
  end

  attr :item, :map, required: true
  attr :single, :boolean, required: true
  attr :language, :string, required: true

  defp item(assigns) do
    ~H"""
    <article
      id={"item-#{@item.id}"}
      class={[
        if(@single,
          do: "mt-9",
          else: "grid gap-1 border-b border-line py-4 sm:grid-cols-[76px_1fr] sm:gap-4"
        )
      ]}
    >
      <div :if={!@single} class="pt-0.5 text-[11px] tracking-[.06em] text-text uppercase">
        {Words.t(@language, kind_word(@item.kind))}
      </div>
      <div class="min-w-0">
        <h2 class={["font-semibold break-words", if(@single, do: "text-[15px]", else: "text-sm")]}>
          {title(@item)}
        </h2>
        <div class={[
          "font-mono text-xs break-all text-text",
          if(@single, do: "mt-0.5 mb-5", else: "mt-px mb-1.5")
        ]}>
          {meta(@item)}
        </div>

        <div :if={@item.status == :running} role="status">
          <p class={[
            "flex items-center gap-3 text-text",
            if(@single, do: "text-xl sm:text-[22px]", else: "text-base")
          ]}>
            <span class="tldr-pulse size-2.5 shrink-0 rounded-full bg-brand" aria-hidden="true"></span>
            {Words.t(@language, waiting_word(@item.kind))}
          </p>
          <p :if={@item.kind == :youtube} class="mt-1 pl-[22px] text-sm text-text">
            {Words.t(@language, :waiting_video_hint)}
          </p>
        </div>

        <p :if={@item.status == :error} class="text-[#ff6b5f]">
          {message(@item.error, @language)}
        </p>

        <div :if={@item.status == :done}>
          <p class={[
            if(@single,
              do: "mb-5 text-xl leading-snug font-medium sm:text-[22px]",
              else: "mb-1.5 text-base"
            )
          ]}>
            {@item.summary.tldr}
          </p>
          <ul :if={@item.summary.points != []} class={if(@single, do: "space-y-2", else: "space-y-1")}>
            <li
              :for={point <- @item.summary.points}
              class={[
                "relative pl-4 before:absolute before:left-0 before:text-text before:content-['–']",
                if(@single, do: "text-text", else: "text-sm text-text")
              ]}
            >
              {point}
            </li>
          </ul>
          <div class={[
            "flex gap-5 text-text",
            if(@single, do: "mt-7 text-[15px]", else: "mt-2 text-xs")
          ]}>
            <button
              type="button"
              class="cursor-pointer hover:text-brand"
              data-copy={copy_text(@item.summary)}
              data-copied={Words.t(@language, :copied)}
              phx-click={JS.dispatch("tldr:copy")}
            >
              {Words.t(@language, :copy)}
            </button>
            <a href={@item.summary.url} target="_blank" rel="noopener" class="hover:text-brand">
              {Words.t(@language, :open)} ↗
            </a>
          </div>
        </div>
      </div>
    </article>
    """
  end

  defp new_item(address) do
    kind =
      case Source.parse(address) do
        {:ok, {kind, _url}} -> kind
        {:error, _} -> :web
      end

    %{
      id: System.unique_integer([:positive]),
      address: address,
      kind: kind,
      status: :running,
      started: System.monotonic_time(:millisecond)
    }
  end

  defp seconds_since(item),
    do: Float.round((System.monotonic_time(:millisecond) - item.started) / 1000, 1)

  defp title(%{status: :done, summary: %{title: title}}) when is_binary(title), do: title
  defp title(item), do: item.address

  defp meta(%{status: :done, summary: summary} = item) do
    host = URI.parse(summary.url).host |> String.replace_prefix("www.", "")

    Enum.join(
      Enum.reject([host, summary.channel, "#{format_seconds(item.seconds)} s"], &is_nil/1),
      " · "
    )
  end

  defp meta(%{status: :error} = item), do: "#{format_seconds(item.seconds)} s"
  defp meta(%{status: :running}), do: nil

  defp format_seconds(seconds),
    do: seconds |> :erlang.float_to_binary(decimals: 1) |> String.replace(".", ",")

  defp kind_word(:youtube), do: :video
  defp kind_word(:web), do: :page

  defp waiting_word(:youtube), do: :waiting_video
  defp waiting_word(:web), do: :waiting_page

  defp copy_text(summary) do
    points = Enum.map_join(summary.points, "\n", &"- #{&1}")

    Enum.join(
      Enum.reject([summary.title, summary.tldr, points, summary.url], &(&1 in [nil, ""])),
      "\n\n"
    )
  end

  @doc false
  # Every reason `Tldr.Summarizer.summarize/2` can return, as a sentence.
  def message(reason, language), do: Words.t(language, word(reason), bindings(reason))

  defp word(:invalid_url), do: :invalid_url
  defp word({:http_status, status}) when status in [401, 403], do: :blocked
  defp word({:http_status, 404}), do: :not_found
  defp word({:http_status, 429}), do: :too_many
  defp word({:http_status, _status}), do: :http_status
  defp word(:not_html), do: :not_html
  defp word(:empty_page), do: :empty_page
  defp word({:unreachable, _}), do: :unreachable
  defp word({:openrouter, _}), do: :openrouter
  defp word(:invalid_answer), do: :invalid_answer
  defp word(_), do: :failed

  defp bindings({:http_status, status}), do: [status: status]
  defp bindings({:openrouter, detail}), do: [detail: detail]
  defp bindings(_), do: []
end
