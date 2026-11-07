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

  alias Tldr.{Job, Source, Summary}
  alias TldrWeb.Words

  # Switches the words and the language of the next summaries. The ones
  # already there stay as they are; summarizing them again would cost money.
  on_mount TldrWeb.LanguageHook

  @impl true
  def mount(_params, session, socket) do
    params = get_connect_params(socket) || %{}

    {:ok,
     assign(socket,
       page_title: "tldr.tf",
       items: [],
       submits: 0,
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
        item = Map.merge(Map.delete(item, :saved), %{status: :running})
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

    item = socket.assigns.items |> Enum.find(&(&1.id == id)) |> Map.merge(outcome)

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
    assigns =
      assign(assigns,
        single: length(assigns.items) <= 1,
        empty: assigns.items == [] and not assigns.embedded
      )

    ~H"""
    <Layouts.app flash={@flash}>
      <Layouts.page
        data-layout={if @single, do: "single", else: "list"}
        class="pt-6 sm:pt-8"
      >
        <Layouts.header language={@language} home={if @embedded, do: :site, else: :none} />

        <h1
          :if={@empty}
          class="mt-14 mb-8 text-[40px] leading-[1.1] font-bold tracking-tight text-balance sm:mt-[10vh] sm:text-[48px]"
        >
          <span
            :for={sentence <- Words.sentences(Words.t(@language, :headline))}
            class="block sm:inline"
          >
            {sentence}
          </span>
        </h1>

        <.form :if={!@embedded} for={%{}} id="summarize" phx-submit="summarize">
          <div class="flex flex-col sm:h-12 sm:flex-row">
            <input
              type="text"
              id={"addresses-#{@submits}"}
              name="addresses"
              aria-label={Words.t(@language, :placeholder)}
              placeholder={
                Words.t(@language, if(@items == [], do: :placeholder, else: :placeholder_more))
              }
              autocomplete="off"
              spellcheck="false"
              data-1p-ignore
              data-lpignore="true"
              phx-mounted={JS.focus()}
              class="h-12 w-full min-w-0 border border-line bg-bg sm:w-auto sm:flex-1 px-4 text-base leading-none text-text placeholder:text-text/50 outline-none focus:border-brand sm:border-r-0"
            />
            <button
              type="submit"
              class="h-11 shrink-0 cursor-pointer border border-brand bg-brand px-6 sm:h-12 text-base leading-none font-medium text-white hover:bg-rose-700 -mt-px sm:mt-0 sm:-ml-px sm:w-[180px]"
            >
              {Words.t(@language, :submit)}
            </button>
          </div>
          <p :if={@items == []} class="mt-3 text-sm">
            <span
              :for={sentence <- Words.sentences(Words.t(@language, :hint))}
              class="block sm:inline"
            >
              {sentence}
            </span>
          </p>
        </.form>

        <div id="summaries" class={if(@embedded, do: "", else: "mt-6 sm:mt-10")}>
          <.item
            :for={item <- @items}
            item={item}
            single={@single}
            language={@language}
            offset={@offset}
          />
        </div>

        <:footer>
          <Layouts.footer language={@language} embedded={@embedded} />
        </:footer>
      </Layouts.page>
    </Layouts.app>
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
      class={
        if(@single, do: "", else: "border-t border-line py-6 first:border-t-0 first:pt-0 sm:py-8")
      }
    >
      <div class="flex items-start gap-4 sm:gap-5">
        <div class="min-w-0 flex-1">
          <div
            title={@item.address}
            class={[
              "text-sm leading-5",
              if(@item.status == :done, do: "mb-2 truncate", else: "truncate")
            ]}
          >
            {meta(@item, @language, @offset)}
          </div>
          <h2
            :if={@item.status == :done}
            class="text-lg leading-6 font-semibold break-words sm:text-xl sm:leading-[26px]"
          >
            {title(@item)}
          </h2>
          <div :if={@item.status == :running} role="status" class="mt-3">
            <p class="flex items-start gap-1.5 text-base leading-normal">
              <span
                class="flex h-6 w-3.5 shrink-0 items-center justify-center"
                aria-hidden="true"
              >
                <span class="tldr-pulse size-2 translate-y-[0.5px] rounded-full bg-brand"></span>
              </span>
              {Words.t(@language, waiting_word(@item.kind))}
            </p>
            <p :if={@item.kind == :youtube} class="mt-1 pl-5 text-[13px]">
              {Words.t(@language, :waiting_video_hint)}
            </p>
          </div>

          <p
            :if={@item.status == :error}
            class="mt-3 flex items-start gap-1.5 text-base leading-normal"
          >
            <span
              class="flex h-6 w-3.5 shrink-0 items-center justify-center"
              aria-hidden="true"
            >
              <.icon
                name="hero-exclamation-circle-mini"
                class="size-3.5! translate-y-[0.5px] text-brand"
              />
            </span>
            {message(@item.error, @language)}
          </p>
          <div :if={@item.status == :error && @item.url} class="mt-3">
            <.open_link href={@item.url} class="text-[15px] font-medium" language={@language} />
          </div>
        </div>
        <img
          :if={@item.video}
          src={~p"/thumbnail/#{@item.video}"}
          alt=""
          class="aspect-video w-[85px] shrink-0 bg-line object-cover sm:w-[89px]"
        />
      </div>

      <div :if={@item.status == :done} class="mt-4">
        <p class={[
          "mb-5 max-w-[34rem] text-pretty sm:mb-6",
          if(@single,
            do: "text-xl leading-[1.35] sm:text-2xl",
            else: "text-xl leading-[1.35] sm:text-[22px]"
          )
        ]}>
          {keep_compounds(@item.summary.tldr)}
        </p>
        <ul
          :if={@item.summary.points != []}
          class="max-w-[34rem] space-y-2.5 text-base leading-normal text-pretty sm:space-y-3"
        >
          <li
            :for={point <- @item.summary.points}
            class="relative pl-5 before:absolute before:left-0 before:w-3.5 before:text-center before:content-['–']"
          >
            {keep_compounds(point)}
          </li>
        </ul>
        <div class="mt-5 flex gap-6 text-[15px] font-medium sm:mt-6 sm:gap-5">
          <button
            type="button"
            class="group -my-3 inline-flex cursor-pointer items-center gap-1.5 py-3"
            data-copy={copy_text(@item.summary)}
            data-copied={Words.t(@language, :copied)}
            phx-click={JS.dispatch("tldr:copy")}
          >
            <span
              data-copy-label
              class="underline decoration-line-strong underline-offset-4 group-hover:decoration-text"
            >
              {Words.t(@language, :copy)}
            </span>
            <.icon name="hero-square-2-stack" class="size-4" />
          </button>
          <.open_link href={@item.summary.url} language={@language} />
          <button
            :if={@item[:saved]}
            type="button"
            class="-my-3 cursor-pointer py-3 underline decoration-line-strong underline-offset-4 hover:decoration-text"
            phx-click="refresh"
            phx-value-id={@item.id}
          >
            {Words.t(@language, :refresh)}
          </button>
        </div>
      </div>
    </article>
    """
  end

  attr :href, :string, required: true
  attr :language, :string, required: true
  attr :class, :string, default: nil

  # "Open link" with its arrow outside the underline, like the glyph of Copy.
  defp open_link(assigns) do
    ~H"""
    <a
      href={@href}
      target="_blank"
      rel="noopener"
      class={["group -my-3 inline-flex items-center gap-1.5 py-3", @class]}
    >
      <span class="underline decoration-line-strong underline-offset-4 group-hover:decoration-text">
        {Words.t(@language, :open)}
      </span>
      <.icon name="hero-arrow-up-right" class="size-3.5" />
    </a>
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
  # one goes in its full form. An address that is not valid is left out.
  defp share_path(items), do: "/" <> Enum.map_join(items, &(&1.url || ""))

  # `url` is the full form of the address without its fragment, which would
  # hide the rest of the address bar from the server. It is nil when the
  # address is not valid. The browser keeps summaries under it, and a failed
  # item's "Open link" leads there.
  defp new_item(address) do
    {kind, url} =
      case Source.parse(address) do
        {:ok, {kind, url}} -> {kind, url |> String.split("#") |> hd()}
        {:error, _} -> {:web, nil}
      end

    %{
      id: System.unique_integer([:positive]),
      address: address,
      url: url,
      kind: kind,
      video: Source.video_id(address),
      status: :running
    }
  end

  defp title(%{summary: %{title: title}}) when is_binary(title), do: title
  defp title(%{summary: summary}), do: host(summary.url)

  # The line above the title: where it comes from, place first. A page names
  # its host, a video YouTube and its channel; a kept summary adds when it
  # was saved. Before the summary arrives, and when it fails, the line holds
  # the bare address and there is no title.
  defp meta(%{status: :done} = item, language, offset) do
    Enum.join(Enum.reject([source(item), saved(item, language, offset)], &is_nil/1), " · ")
  end

  defp meta(%{video: id}, _language, _offset) when is_binary(id), do: "youtu.be/" <> id
  defp meta(item, _language, _offset), do: bare(item.address)

  defp source(%{kind: :youtube, summary: %{channel: channel}}) when is_binary(channel),
    do: "YouTube · " <> channel

  defp source(%{kind: :youtube}), do: "YouTube"
  defp source(%{summary: summary}), do: host(summary.url)

  # `saved` is in milliseconds since 1970, `offset` the reader's time zone.
  defp saved(%{saved: saved}, language, offset) do
    date = saved |> DateTime.from_unix!(:millisecond) |> DateTime.add(offset, :minute)
    format = if language == "de", do: "%-d.%-m.%Y, %H:%M", else: "%b %-d, %Y, %H:%M"
    Words.t(language, :saved, date: Calendar.strftime(date, format))
  end

  defp saved(_item, _language, _offset), do: nil

  # An address as a person reads it: no scheme, no "www.".
  defp bare(address), do: String.replace(address, ~r{\A\s*(https?://)?(www\.)?}i, "")

  # A hyphen inside a word ("co-founder") does not break the lead line.
  defp keep_compounds(text), do: String.replace(text, ~r/(?<=\w)-(?=\w)/u, "\u2011")

  defp host(address) do
    case URI.parse(address) do
      %URI{host: host} when is_binary(host) and host != "" ->
        String.replace_prefix(host, "www.", "")

      _ ->
        nil
    end
  end

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
