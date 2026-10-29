defmodule Tldr.SourceTest do
  use ExUnit.Case, async: true

  alias Tldr.Source

  @watch "https://www.youtube.com/watch?v=jNQXAC9IVRw"

  test "every common YouTube address becomes the canonical watch address" do
    for url <- [
          "https://www.youtube.com/watch?v=jNQXAC9IVRw",
          "https://youtube.com/watch?v=jNQXAC9IVRw&t=42s",
          "https://m.youtube.com/watch?feature=share&v=jNQXAC9IVRw",
          "https://youtu.be/jNQXAC9IVRw?si=abc",
          "https://www.youtube.com/shorts/jNQXAC9IVRw",
          "https://www.youtube.com/live/jNQXAC9IVRw",
          "https://www.youtube.com/embed/jNQXAC9IVRw",
          "youtu.be/jNQXAC9IVRw"
        ] do
      assert Source.parse(url) == {:ok, {:youtube, @watch}}, url
    end
  end

  test "any other http address is a web page" do
    assert Source.parse("https://paulgraham.com/greatwork.html") ==
             {:ok, {:web, "https://paulgraham.com/greatwork.html"}}

    assert Source.parse("  example.com/a  ") == {:ok, {:web, "https://example.com/a"}}
  end

  test "a YouTube address without a video is a web page" do
    assert Source.parse("https://www.youtube.com/@veritasium") ==
             {:ok, {:web, "https://www.youtube.com/@veritasium"}}
  end

  test "anything that is not an http address is refused" do
    assert Source.parse("") == {:error, :invalid_url}
    assert Source.parse("not a url") == {:error, :invalid_url}
    assert Source.parse("ftp://example.com/file") == {:error, :invalid_url}
    assert Source.parse("http://localhost:4000") == {:error, :invalid_url}
  end
end
