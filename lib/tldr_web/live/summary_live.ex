defmodule TldrWeb.SummaryLive do
  @moduledoc """
  The one page: an input for addresses and their summaries.

  One summary gets the calm single layout. From the second one on the page
  becomes a list, newest first. Every address runs in its own async task,
  so several run at once. The list lives in this process only, but its
  addresses go into the address bar (`/<address><address>`). Opening that
  address, or reloading it, summarizes them again (`docs/decisions/011`).

  The summaries run as `Tldr.Job`s, so they go on when the page is gone,
  and the reader's browser keeps the ones that are done
  (`docs/decisions/012`). Its connect params bring them back:

    * `tab`, the id of the browser tab, finds the tab's jobs again
    * `kept`, the browser's summaries of the addresses in the address bar
    * `offset`, the browser's time zone in minutes east of UTC, for the
      date a kept summary was saved
  """

  use TldrWeb, :live_view

  alias Tldr.{Job, Language, Source, Summary}
  alias TldrWeb.Words

  @impl true
  def mount(_params, session, socket) do
    language = Language.known(session["language"]) || Language.default()
    params = get_connect_params(socket) || %{}

    {:ok,
     assign(socket,
       page_title: "tldr.tf",
       items: [],
       submits: 0,
       language: language,
       embedded: session["embedded"] == true,
       tab: params["tab"],
       kept: kept(params["kept"]),
       offset: if(params["offset"] in -900..900, do: params["offset"], else: 0)
     )}
  end

  defmodule NotFound do
    defexception message: "not an address", plug_status: 404
  end

  # A shared address bar fills an empty page. Later patches come from
  # `summarize` itself and change nothing here.
  @impl true
  def handle_params(_params, uri, %{assigns: %{items: []}} = socket) do
    case paste(uri) do
      nil -> {:noreply, socket}
      paste -> {:noreply, summarize(socket, paste)}
    end
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  # Switches the words and the language of the next summaries. The ones
  # already there stay as they are; summarizing them again would cost money.
  @impl true
  def handle_event("language", %{"language" => language}, socket) do
    {:noreply, assign(socket, language: Language.known(language) || socket.assigns.language)}
  end

  @impl true
  def handle_event("summarize", %{"addresses" => paste}, socket) do
    socket = summarize(socket, paste)

    # A new input id renders a fresh, empty, focused input after every submit.
    {:noreply,
     socket
     |> assign(submits: socket.assigns.submits + 1)
     |> push_patch(to: share_path(socket.assigns.items), replace: true)}
  end

  # Summarizes a kept address again and replaces it.
  def handle_event("refresh", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.items, &(to_string(&1.id) == id)) do
      %{saved: _} = item ->
        item = Map.merge(Map.delete(item, :saved), %{status: :running, started: now()})
        socket = run(socket, item, fresh: true)
        {:noreply, assign(socket, items: replace(socket.assigns.items, item))}

      _gone ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_async({:summary, id}, result, socket) do
    outcome =
      case result do
        {:ok, {:ok, summary}} -> %{status: :done, summary: summary}
        {:ok, {:error, reason}} -> %{status: :error, error: reason}
        {:exit, _reason} -> %{status: :error, error: :crashed}
      end

    item = Enum.find(socket.assigns.items, &(&1.id == id))
    item = Map.merge(item, Map.put(outcome, :seconds, seconds_since(item)))

    {:noreply,
     socket
     |> assign(items: replace(socket.assigns.items, item))
     |> keep(item)}
  end

  # Hands a new summary to the browser, which keeps it with today's date.
  defp keep(socket, %{status: :done, url: url, summary: summary}) when is_binary(url) do
    push_event(socket, "tldr:keep", %{
      url: url,
      language: socket.assigns.language,
      summary: Map.from_struct(summary)
    })
  end

  defp keep(socket, _item), do: socket

  defp replace(items, %{id: id} = item),
    do: Enum.map(items, &if(&1.id == id, do: item, else: &1))

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
          <a
            :if={@embedded}
            id="panel-home"
            href="https://tldr.tf"
            target="_blank"
            rel="noopener"
            class="mb-8 block w-fit hover:opacity-80"
          >
            <Layouts.wordmark class="text-5xl sm:text-6xl" />
          </a>
          <Layouts.wordmark :if={@single && !@embedded} class="mb-8 block text-5xl sm:text-6xl" />

          <.form
            :if={!@embedded}
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
            <Layouts.wordmark :if={!@single} class="text-[19px]" />
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

          <div :if={@single || @embedded} class="mt-4 flex items-baseline gap-4 text-sm text-text">
            <p class="flex-1">{if @items == [] && !@embedded, do: Words.t(@language, :hint)}</p>
            <.languages language={@language} />
          </div>

          <div id="summaries">
            <.item
              :for={item <- @items}
              item={item}
              single={@single}
              language={@language}
              offset={@offset}
            />
          </div>
        </div>

        <Layouts.footer language={@language} embedded={@embedded} />
      </div>
    </Layouts.app>
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
  attr :offset, :integer, required: true

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
        <div class={["flex items-start gap-3", if(@single, do: "mb-5", else: "mb-1.5")]}>
          <img
            :if={@item.video}
            src={~p"/thumbnail/#{@item.video}"}
            alt=""
            class={["aspect-video shrink-0 object-cover", if(@single, do: "w-28", else: "w-24")]}
          />
          <div class="min-w-0">
            <h2 class={[
              "font-semibold break-words",
              if(@single, do: "text-[15px]", else: "text-sm")
            ]}>
              {title(@item)}
            </h2>
            <div class={[
              "font-mono text-xs break-all text-text",
              if(@single, do: "mt-0.5", else: "mt-px")
            ]}>
              {meta(@item, @language, @offset)}
            </div>
          </div>
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
            <button
              :if={@item[:saved]}
              type="button"
              class="cursor-pointer hover:text-brand"
              phx-click="refresh"
              phx-value-id={@item.id}
            >
              {Words.t(@language, :refresh)}
            </button>
          </div>
        </div>
      </div>
    </article>
    """
  end

  # Puts one item per address in the paste on top. One the browser kept
  # shows at once, every other one starts its job.
  defp summarize(socket, paste) do
    new_items =
      paste
      |> Source.addresses()
      |> Enum.map(&new_item/1)
      |> Enum.map(fn item ->
        case socket.assigns.kept[{item.url, socket.assigns.language}] do
          nil -> item
          kept -> Map.merge(item, %{status: :done, summary: kept.summary, saved: kept.saved})
        end
      end)

    socket =
      new_items
      |> Enum.filter(&(&1.status == :running))
      |> Enum.reduce(socket, &run(&2, &1))

    assign(socket, items: new_items ++ socket.assigns.items)
  end

  # Waits for the item's job. The key finds the job again when this tab
  # comes back with a new page process; without a tab no one else finds it.
  defp run(socket, item, opts \\ []) do
    %{tab: tab, language: language} = socket.assigns
    key = {tab || make_ref(), item.url || item.address, language}
    opts = [language: language] ++ opts

    start_async(socket, {:summary, item.id}, fn -> Job.summarize(key, item.address, opts) end)
  end

  # The summaries the browser sent along, by address and language. Anything
  # malformed is left out; that address is summarized again.
  @latest_saved 253_402_300_799_999

  defp kept(entries) when is_list(entries) do
    for %{"url" => url, "language" => language, "saved" => saved, "summary" => summary} <-
          entries,
        is_binary(url) and saved in 0..@latest_saved,
        summary = kept_summary(summary),
        into: %{},
        do: {{url, language}, %{summary: summary, saved: saved}}
  end

  defp kept(_entries), do: %{}

  defp kept_summary(%{"url" => url, "kind" => kind, "tldr" => tldr, "points" => points} = map)
       when is_binary(url) and kind in ["web", "youtube"] and is_binary(tldr) and
              is_list(points) do
    if Enum.all?(points, &is_binary/1) and optional_text?(map["title"]) and
         optional_text?(map["channel"]) do
      %Summary{
        url: url,
        kind: String.to_existing_atom(kind),
        title: map["title"],
        channel: map["channel"],
        tldr: tldr,
        points: points
      }
    end
  end

  defp kept_summary(_summary), do: nil

  defp optional_text?(value), do: is_nil(value) or is_binary(value)

  # Everything after the host is the paste, its query string included, so
  # the query of an address stays its own. Some proxies merge `//` into `/`.
  # The bare page has no paste; any other path is not found.
  defp paste(uri) do
    case URI.parse(uri) do
      %URI{path: path} when path in [nil, "/"] ->
        nil

      %URI{path: "/" <> path, query: query} ->
        paste = if query, do: path <> "?" <> query, else: path
        paste = String.replace(paste, ~r{(https?:)/(?!/)}, "\\1//")
        if paste =~ ~r{\Ahttps?://}, do: paste, else: raise(NotFound)
    end
  end

  # The page's addresses in the order shown, back to back after the host.
  # `Tldr.Source.addresses/1` splits them again at each `https://`, so each
  # one goes in its full form. A fragment would hide the rest of the address
  # from the server; an address that is not valid is left out.
  defp share_path(items) do
    "/" <>
      Enum.map_join(items, fn item ->
        if item.url, do: item.url |> String.split("#") |> hd(), else: ""
      end)
  end

  # `url` is the full form of the address, nil when it is not valid.
  defp new_item(address) do
    {kind, url} =
      case Source.parse(address) do
        {:ok, {kind, url}} -> {kind, url}
        {:error, _} -> {:web, nil}
      end

    %{
      id: System.unique_integer([:positive]),
      address: address,
      url: url,
      kind: kind,
      video: Source.video_id(address),
      status: :running,
      started: now()
    }
  end

  defp now, do: System.monotonic_time(:millisecond)

  defp seconds_since(item), do: Float.round((now() - item.started) / 1000, 1)

  defp title(%{status: :done, summary: %{title: title}}) when is_binary(title), do: title
  defp title(item), do: item.address

  # A kept summary says when it was saved, a new one how long it took.
  defp meta(%{status: :done, summary: summary} = item, language, offset) do
    host = URI.parse(summary.url).host |> String.replace_prefix("www.", "")

    time =
      case item do
        %{saved: saved} -> Words.t(language, :saved, date: format_saved(saved, language, offset))
        _new -> "#{format_seconds(item.seconds)} s"
      end

    Enum.join(Enum.reject([host, summary.channel, time], &is_nil/1), " · ")
  end

  defp meta(%{status: :error} = item, _language, _offset), do: "#{format_seconds(item.seconds)} s"
  defp meta(%{status: :running}, _language, _offset), do: nil

  # `saved` is in milliseconds since 1970, `offset` the reader's time zone.
  defp format_saved(saved, language, offset) do
    date = saved |> DateTime.from_unix!(:millisecond) |> DateTime.add(offset, :minute)
    format = if language == "de", do: "%-d.%-m.%Y, %H:%M", else: "%b %-d, %Y, %H:%M"
    Calendar.strftime(date, format)
  end

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
