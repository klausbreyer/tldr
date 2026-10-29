defmodule Tldr.SummarizerTest do
  use ExUnit.Case, async: true

  alias Tldr.{Summarizer, Summary}

  @answer %{"tldr" => "In short.", "points" => ["One", "Two", "Three"]}

  setup do
    test = self()

    Req.Test.stub(Tldr.OpenRouter, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      send(test, {:request, Jason.decode!(body)})

      Req.Test.json(conn, %{
        "choices" => [%{"message" => %{"content" => Jason.encode!(@answer)}}]
      })
    end)

    :ok
  end

  test "a web page is sent to the model as text" do
    Req.Test.stub(Tldr.Page, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, "<title>An essay</title><p>The essay text.</p>")
    end)

    assert {:ok, summary} = Summarizer.summarize("https://example.com/essay")

    assert summary == %Summary{
             url: "https://example.com/essay",
             kind: :web,
             title: "An essay",
             tldr: "In short.",
             points: ["One", "Two", "Three"]
           }

    assert_received {:request, request}
    assert [%{"role" => "system"}, %{"role" => "user", "content" => [text]}] = request["messages"]
    assert text["text"] =~ "The essay text."
    assert request["response_format"]["type"] == "json_schema"
  end

  test "a YouTube video is sent to the model as a video, routed to AI Studio" do
    Req.Test.stub(
      Tldr.YouTube,
      &Req.Test.json(&1, %{"title" => "A talk", "author_name" => "A channel"})
    )

    assert {:ok, %Summary{kind: :youtube, title: "A talk", channel: "A channel"}} =
             Summarizer.summarize("https://youtu.be/jNQXAC9IVRw")

    assert_received {:request, request}
    assert request["provider"] == %{"only" => ["google-ai-studio"]}
    assert [_system, %{"content" => [_text, video]}] = request["messages"]

    assert video == %{
             "type" => "video_url",
             "video_url" => %{"url" => "https://www.youtube.com/watch?v=jNQXAC9IVRw"}
           }
  end

  test "the summary is written in the language asked for, English by default" do
    Req.Test.stub(Tldr.Page, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, "<p>Text</p>")
    end)

    Summarizer.summarize("https://example.com")
    assert_received {:request, %{"messages" => [%{"content" => system} | _]}}
    assert system =~ "Write in English."

    Summarizer.summarize("https://example.com", language: "de")
    assert_received {:request, %{"messages" => [%{"content" => system} | _]}}
    assert system =~ "Write in German."
  end

  test "an invalid address never reaches the model" do
    assert Summarizer.summarize("nope") == {:error, :invalid_url}
    refute_received {:request, _}
  end

  test "a connection that closes before the answer is tried again" do
    Req.Test.stub(Tldr.Page, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, "<p>Text</p>")
    end)

    {:ok, calls} = Agent.start_link(fn -> 0 end)

    Req.Test.stub(Tldr.OpenRouter, fn conn ->
      if Agent.get_and_update(calls, &{&1, &1 + 1}) == 0 do
        Req.Test.transport_error(conn, :closed)
      else
        Req.Test.json(conn, %{
          "choices" => [%{"message" => %{"content" => Jason.encode!(@answer)}}]
        })
      end
    end)

    assert {:ok, %Summary{tldr: "In short."}} = Summarizer.summarize("https://example.com")
    assert Agent.get(calls, & &1) == 2
  end

  test "an error from OpenRouter comes back as an error" do
    Req.Test.stub(Tldr.Page, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, "<p>Text</p>")
    end)

    Req.Test.stub(Tldr.OpenRouter, fn conn ->
      conn
      |> Plug.Conn.put_status(402)
      |> Req.Test.json(%{"error" => %{"message" => "Insufficient credits"}})
    end)

    assert Summarizer.summarize("https://example.com") ==
             {:error, {:openrouter, "Insufficient credits"}}
  end
end
