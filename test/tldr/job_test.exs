defmodule Tldr.JobTest do
  use ExUnit.Case, async: true

  alias Tldr.Job

  setup do
    test = self()

    Req.Test.stub(Tldr.Page, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.send_resp(200, "<title>A page</title><main>Text.</main>")
    end)

    # Every model call reports itself and waits for the test to answer it.
    Req.Test.stub(Tldr.OpenRouter, fn conn ->
      send(test, {:model, self()})

      receive do
        {:answer, tldr} ->
          answer = Jason.encode!(%{"tldr" => tldr, "points" => []})
          Req.Test.json(conn, %{"choices" => [%{"message" => %{"content" => answer}}]})
      end
    end)

    %{key: make_ref()}
  end

  test "a job goes on when its page is gone, and the page gets it on return", %{key: key} do
    {:ok, page} = Task.start(fn -> Job.summarize(key, "https://example.com/a") end)
    assert_receive {:model, model}
    Process.exit(page, :kill)

    back = Task.async(fn -> Job.summarize(key, "https://example.com/a") end)
    send(model, {:answer, "First."})

    assert {:ok, %{tldr: "First."}} = Task.await(back)
    assert {:ok, %{tldr: "First."}} = Job.summarize(key, "https://example.com/a")
    refute_received {:model, _}
  end

  test "fresh runs the summary again", %{key: key} do
    first = Task.async(fn -> Job.summarize(key, "https://example.com/a") end)
    assert_receive {:model, model}
    send(model, {:answer, "First."})
    assert {:ok, %{tldr: "First."}} = Task.await(first)

    again = Task.async(fn -> Job.summarize(key, "https://example.com/a", fresh: true) end)
    assert_receive {:model, model}
    send(model, {:answer, "Second."})
    assert {:ok, %{tldr: "Second."}} = Task.await(again)
  end
end
