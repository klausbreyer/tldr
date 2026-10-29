defmodule Tldr.LanguageTest do
  use ExUnit.Case, async: true

  alias Tldr.Language

  test "the browser's first known language wins, English when none is known" do
    assert Language.from_accept_language("de-DE,de;q=0.9,en;q=0.8") == "de"
    assert Language.from_accept_language("fr-FR,fr;q=0.9,de;q=0.5") == "de"
    assert Language.from_accept_language("en-US,en;q=0.9,de;q=0.8") == "en"
    assert Language.from_accept_language("fr-FR") == "en"
    assert Language.from_accept_language(nil) == "en"
  end

  test "quality values order the browser's languages" do
    assert Language.from_accept_language("en;q=0.5,de;q=0.9") == "de"
  end

  test "only known languages pass" do
    assert Language.known("de") == "de"
    assert Language.known("xx") == nil
    assert Language.known(nil) == nil
  end
end
