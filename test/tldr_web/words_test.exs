defmodule TldrWeb.WordsTest do
  use ExUnit.Case, async: true

  test "every language has every sentence" do
    [first | rest] = Tldr.Language.all()

    for language <- rest do
      assert TldrWeb.Words.keys(language) == TldrWeb.Words.keys(first), language
    end
  end
end
