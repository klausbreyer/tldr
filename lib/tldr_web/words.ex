defmodule TldrWeb.Words do
  @moduledoc """
  Every sentence the interface says, in every language of `Tldr.Language`.

  `t(language, key)` looks one up. A key that exists in one language must
  exist in all of them; the test for this module checks that.
  """

  @words %{
    "de" => %{
      placeholder: "Link einfügen",
      placeholder_more: "Weiterer Link",
      submit: "Zusammenfassen",
      hint: "Webseite oder YouTube. Mehrere Links auf einmal gehen auch.",
      description: "Webseite oder YouTube in einem Satz und ein paar Punkten.",
      page: "Seite",
      video: "Video",
      waiting_page: "Seite wird gelesen …",
      waiting_video: "Video wird geschaut …",
      waiting_video_hint: "Lange Videos brauchen bis zu einer Minute.",
      copy: "Kopieren",
      copied: "Kopiert",
      open: "Quelle öffnen",
      language: "Sprache",
      invalid_url: "Das ist keine gültige Adresse.",
      blocked: "Die Seite blockt automatische Abrufe.",
      not_found: "Die Seite gibt es nicht (404).",
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
      placeholder: "Paste a link",
      placeholder_more: "Another link",
      submit: "Summarize",
      hint: "A web page or YouTube. Several links at once work too.",
      description: "A web page or YouTube video in one sentence and a few points.",
      page: "Page",
      video: "Video",
      waiting_page: "Reading the page …",
      waiting_video: "Watching the video …",
      waiting_video_hint: "Long videos take up to a minute.",
      copy: "Copy",
      copied: "Copied",
      open: "Open source",
      language: "Language",
      invalid_url: "That is not a valid address.",
      blocked: "The page blocks automated requests.",
      not_found: "The page does not exist (404).",
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

  @doc false
  def keys(language), do: @words |> Map.fetch!(language) |> Map.keys() |> Enum.sort()
end
