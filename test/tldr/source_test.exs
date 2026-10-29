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

  test "a video address gives its id, any other address none" do
    assert Source.video_id("youtu.be/jNQXAC9IVRw?si=abc") == "jNQXAC9IVRw"
    assert Source.video_id("https://www.youtube.com/@veritasium") == nil
    assert Source.video_id("kein-link") == nil
  end

  test "anything that is not an http address is refused" do
    assert Source.parse("") == {:error, :invalid_url}
    assert Source.parse("not a url") == {:error, :invalid_url}
    assert Source.parse("ftp://example.com/file") == {:error, :invalid_url}
    assert Source.parse("http://localhost:4000") == {:error, :invalid_url}
  end

  test "a paste becomes its addresses, also when line breaks were lost" do
    assert Source.addresses("") == []

    assert Source.addresses("  https://a.com/x\nyoutu.be/jNQXAC9IVRw  b.org ") ==
             ["https://a.com/x", "youtu.be/jNQXAC9IVRw", "b.org"]

    # A single-line input drops the line breaks of a pasted list.
    assert Source.addresses("https://a.com/xhttps://b.org/y") ==
             ["https://a.com/x", "https://b.org/y"]

    # An address in a query value belongs to the address around it.
    assert Source.addresses("https://google.com/url?q=https://a.com/x") ==
             ["https://google.com/url?q=https://a.com/x"]
  end
end
