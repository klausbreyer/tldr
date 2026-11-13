defmodule TldrWeb.Words do
  @moduledoc """
  Every sentence the interface says, in every language of `Tldr.Language`.

  `t(language, key)` looks one up. A key that exists in one language must
  exist in all of them; the test for this module checks that.
  """

  @words %{
    "de" => %{
      headline: "Jeder Link. Ein Satz.",
      placeholder: "Link einfügen",
      placeholder_more: "Weiterer Link",
      submit: "Zusammenfassen",
      hint: "Eine Webseite oder ein YouTube-Video. Mehrere Links gehen auch.",
      tagline: "tldr.tf, eine Zusammenfassung für jeden Link",
      description: "Webseite oder YouTube in einem Satz und ein paar Punkten.",
      waiting_page: "Seite wird gelesen …",
      waiting_video: "Video wird geschaut …",
      waiting_video_hint: "Lange Videos brauchen bis zu einer Minute.",
      copy: "Kopieren",
      copied: "Kopiert",
      open: "Link öffnen",
      refresh: "Neu laden",
      saved: "gespeichert %{date}",
      today: "heute",
      language: "Sprache",
      chrome_extension: "Chrome-Erweiterung",
      shortcut: "Shortcut",
      shortcut_intro: "Teile einen Link mit tldr. Die Zusammenfassung öffnet sich im Browser.",
      shortcut_download: "Kurzbefehl hinzufügen",
      shortcut_install:
        "Öffne den Link auf deinem iPhone, iPad oder Mac. Bestätige in Apples Kurzbefehle-App mit „Kurzbefehl hinzufügen“.",
      shortcut_ios: "iPhone und iPad",
      shortcut_ios_share: "Halte einen Link gedrückt und wähle „Teilen …“.",
      shortcut_ios_hint: "In Safari geht auch die Teilen-Taste %{share}.",
      shortcut_ios_run: "Scrolle im Teilen-Menü nach unten und tippe auf „tldr“.",
      shortcut_mac: "Mac",
      shortcut_mac_share:
        "Öffne die Webseite in Safari und klicke auf die Teilen-Taste %{share}.",
      shortcut_mac_run: "Wähle „Kurzbefehle“, dann „tldr“ und klicke auf „Teilen“.",
      shortcut_mac_hint:
        "Fehlt Kurzbefehle? Suche in den Systemeinstellungen nach Erweiterungen und aktiviere Kurzbefehle unter Teilen.",
      privacy: "Datenschutz",
      privacy_stored: "Ich speichere nichts über dich.",
      privacy_cache:
        "Jede Zusammenfassung speichere ich mit ihrer Adresse 24 Stunden lang in einer Postgres-Datenbank bei Hetzner, aber nicht, wer sie angefordert hat. Wer dieselbe Adresse in dieser Zeit zusammenfassen lässt, bekommt dieselbe Zusammenfassung. Danach lösche ich sie.",
      privacy_models:
        "Für die Zusammenfassung schicke ich den Text der Seite oder die Adresse des Videos über OpenRouter an Gemini-Modelle von Google.",
      privacy_youtube:
        "Das Vorschaubild eines Videos hole ich selbst bei YouTube und reiche es weiter. Dein Browser spricht dabei nicht mit YouTube.",
      privacy_hosting: "tldr läuft bei bunny.net auf Magic Containers in Frankfurt.",
      open_source: "Open Source",
      invalid_url: "Das ist keine gültige Adresse.",
      blocked: "Die Seite blockt automatische Abrufe.",
      not_found: "Diese Seite gibt es nicht.",
      too_many: "Die Seite bremst zu viele Abrufe. Später nochmal versuchen.",
      http_status: "Die Seite antwortet mit Fehler %{status}.",
      not_html: "Das ist keine Webseite. PDFs und Dateien gehen noch nicht.",
      empty_page: "Auf der Seite steht kein lesbarer Text.",
      unreachable: "Die Seite ist nicht erreichbar.",
      openrouter: "OpenRouter meldet einen Fehler: %{detail}",
      invalid_answer: "Das Modell hat keine brauchbare Antwort geliefert. Nochmal versuchen.",
      failed: "Etwas ist schiefgegangen. Nochmal versuchen."
    },
    "en" => %{
      headline: "Any link. One sentence.",
      placeholder: "Paste a link",
      placeholder_more: "Another link",
      submit: "Summarize",
      hint: "A web page or a YouTube video. Several links work too.",
      tagline: "tldr.tf, a summary for any link",
      description: "A web page or YouTube video in one sentence and a few points.",
      waiting_page: "Reading the page…",
      waiting_video: "Watching the video…",
      waiting_video_hint: "Long videos take up to a minute.",
      copy: "Copy",
      copied: "Copied",
      open: "Open link",
      refresh: "Refresh",
      saved: "saved %{date}",
      today: "today",
      language: "Language",
      chrome_extension: "Chrome extension",
      shortcut: "Shortcut",
      shortcut_intro: "Share a link with tldr. The summary opens in your browser.",
      shortcut_download: "Add Shortcut",
      shortcut_install:
        "Open the link on your iPhone, iPad, or Mac. Select “Add Shortcut” in Apple’s Shortcuts app.",
      shortcut_ios: "iPhone and iPad",
      shortcut_ios_share: "Touch and hold a link, then select “Share…”",
      shortcut_ios_hint: "In Safari, the Share button %{share} works too.",
      shortcut_ios_run: "Scroll down in the share sheet and tap “tldr”.",
      shortcut_mac: "Mac",
      shortcut_mac_share: "Open the web page in Safari and click the Share button %{share}.",
      shortcut_mac_run: "Select “Shortcuts”, then “tldr”, and click “Share”.",
      shortcut_mac_hint:
        "Is Shortcuts missing? Search System Settings for Extensions and enable Shortcuts under Sharing.",
      privacy: "Privacy",
      privacy_stored: "I store nothing about you.",
      privacy_cache:
        "I store every summary with its address for 24 hours in a Postgres database at Hetzner, but not who asked for it. Anyone who summarizes the same address in that time gets the same summary. Then I delete it.",
      privacy_models:
        "To make the summary, I send the text of the page or the address of the video through OpenRouter to Gemini models from Google.",
      privacy_youtube:
        "I get the preview image of a video from YouTube and pass it on to you. Your browser does not contact YouTube.",
      privacy_hosting: "tldr runs on Magic Containers by bunny.net in Frankfurt.",
      open_source: "Open source",
      invalid_url: "That is not a valid address.",
      blocked: "The page blocks automated requests.",
      not_found: "This page does not exist.",
      too_many: "The page limits requests. Try again later.",
      http_status: "The page answers with error %{status}.",
      not_html: "That is not a web page. PDFs and files do not work yet.",
      empty_page: "The page has no readable text.",
      unreachable: "The page cannot be reached.",
      openrouter: "OpenRouter reports an error: %{detail}",
      invalid_answer: "The model gave no usable answer. Try again.",
      failed: "Something went wrong. Try again."
    }
  }

  @doc "The sentence for `key` in `language`, with `%{name}` filled from `bindings`."
  def t(language, key, bindings \\ []) do
    Enum.reduce(bindings, Map.fetch!(@words[language], key), fn {name, value}, text ->
      String.replace(text, "%{#{name}}", to_string(value))
    end)
  end

  @doc "A short text split into its sentences, so each can take its own line."
  def sentences(text), do: String.split(text, ~r/(?<=\.) /)

  @doc false
  def keys(language), do: @words |> Map.fetch!(language) |> Map.keys() |> Enum.sort()
end
