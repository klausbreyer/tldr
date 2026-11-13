defmodule Tldr.JobTest do
  use Tldr.DataCase, async: true

  alias Tldr.{Cache, Job}

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

        :fail ->
          Plug.Conn.send_resp(conn, 400, "")
      end
    end)

    # Jobs are shared by address, so each test has its own.
    %{url: "https://example.com/#{System.unique_integer([:positive])}"}
  end

  # The first summary in a fresh VM loads Req and Floki, which can take
  # longer than assert_receive's default 100 ms on a slow CI runner.
  @wait 1000

  test "a job goes on when its page is gone, and the page gets it on return", %{url: url} do
    {:ok, page} = Task.start(fn -> Job.summarize(url) end)
    assert_receive {:model, model}, @wait
    Process.exit(page, :kill)

    back = Task.async(fn -> Job.summarize(url) end)
    send(model, {:answer, "First."})

    assert {:ok, %{tldr: "First."}, _saved} = Task.await(back)
    refute_received {:model, _}
  end

  test "a finished summary comes from the cache for a day, for every reader", %{url: url} do
    first = Task.async(fn -> Job.summarize(url, language: "de") end)
    assert_receive {:model, model}, @wait
    send(model, {:answer, "Erst."})
    assert {:ok, %{tldr: "Erst."}, nil} = Task.await(first)

    assert {:ok, %{tldr: "Erst."}, %DateTime{}} = Job.summarize(url, language: "de")
    refute_received {:model, _}
  end

  test "fresh runs the summary again and replaces the cached one", %{url: url} do
    Cache.put(%Tldr.Summary{url: url, kind: :web, tldr: "Old.", points: []}, "en")

    again = Task.async(fn -> Job.summarize(url, fresh: true) end)
    assert_receive {:model, model}, @wait
    send(model, {:answer, "New."})
    assert {:ok, %{tldr: "New."}, nil} = Task.await(again)

    assert {:ok, %{tldr: "New."}, %DateTime{}} = Job.summarize(url)
  end

  test "an error is not cached and runs again", %{url: url} do
    failed = Task.async(fn -> Job.summarize(url) end)
    assert_receive {:model, model}, @wait
    send(model, :fail)
    assert {:error, _reason} = Task.await(failed, 5000)

    assert :miss = Cache.fetch(url, "en")
  end

  test "an invalid address fails at once" do
    assert {:error, :invalid_url} = Job.summarize("not an address")
  end
end
