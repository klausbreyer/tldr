defmodule Tldr.CacheTest do
  use Tldr.DataCase, async: true

  alias Tldr.{Cache, Repo, Summary}

  @summary %Summary{
    url: "https://example.com/a",
    kind: :web,
    title: "A page",
    tldr: "The gist.",
    points: ["One.", "Two."]
  }

  test "a summary comes back for its address and language, with the time it was saved" do
    assert :miss = Cache.fetch(@summary.url, "en")
    Cache.put(@summary, "en")

    assert {:ok, @summary, %DateTime{}} = Cache.fetch(@summary.url, "en")
    assert :miss = Cache.fetch(@summary.url, "de")
  end

  test "a newer summary replaces the older one" do
    Cache.put(@summary, "en")
    Cache.put(%{@summary | tldr: "Newer."}, "en")

    assert {:ok, %Summary{tldr: "Newer."}, _saved} = Cache.fetch(@summary.url, "en")
  end

  test "a summary older than a day is gone, and the next one deletes it" do
    Cache.put(@summary, "en")
    Repo.query!("UPDATE summaries SET saved_at = now() - interval '25 hours'")
    assert :miss = Cache.fetch(@summary.url, "en")

    Cache.put(%{@summary | url: "https://example.com/b"}, "en")
    assert %{rows: [[1]]} = Repo.query!("SELECT count(*) FROM summaries")
  end
end
