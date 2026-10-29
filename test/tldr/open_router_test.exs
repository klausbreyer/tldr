defmodule Tldr.OpenRouterTest do
  use ExUnit.Case, async: true

  alias Tldr.OpenRouter

  test "accepts bounded summaries, including sources with no points" do
    for answer <- [
          %{"tldr" => "Too little content to summarize.", "points" => []},
          %{
            "tldr" => String.duplicate("ä", 500),
            "points" => List.duplicate(String.duplicate("ö", 400), 6)
          }
        ] do
      stub_answer(answer)
      assert OpenRouter.complete(%{}) == {:ok, answer}
    end
  end

  test "rejects missing fields, wrong types and extra fields" do
    for answer <- [
          %{},
          %{"tldr" => "Text"},
          %{"tldr" => nil, "points" => []},
          %{"tldr" => %{"html" => "Text"}, "points" => []},
          %{"tldr" => "Text", "points" => nil},
          %{"tldr" => "Text", "points" => "Not a list"},
          %{"tldr" => "Text", "points" => [1]},
          %{"tldr" => "Text", "points" => [%{"text" => "Point"}]},
          %{"tldr" => "Text", "points" => [], "instructions" => "Do something else"}
        ] do
      stub_answer(answer)
      assert OpenRouter.complete(%{}) == {:error, :invalid_answer}
    end
  end

  test "rejects blank or oversized summaries" do
    for answer <- [
          %{"tldr" => " \n ", "points" => []},
          %{"tldr" => "Text", "points" => [" "]},
          %{"tldr" => String.duplicate("a", 501), "points" => []},
          %{"tldr" => "Text", "points" => [String.duplicate("a", 401)]},
          %{"tldr" => "Text", "points" => List.duplicate("Point", 7)}
        ] do
      stub_answer(answer)
      assert OpenRouter.complete(%{}) == {:error, :invalid_answer}
    end
  end

  defp stub_answer(answer) do
    Req.Test.stub(OpenRouter, fn conn ->
      Req.Test.json(conn, %{
        "choices" => [%{"message" => %{"content" => Jason.encode!(answer)}}]
      })
    end)
  end
end
