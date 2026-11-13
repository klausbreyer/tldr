defmodule Tldr.DataCase do
  @moduledoc """
  The test case for tests that reach the database. Each test runs in its
  own transaction. Processes that a test starts find it through
  `$callers`, jobs included.
  """

  use ExUnit.CaseTemplate

  setup tags do
    Tldr.DataCase.checkout(tags)
  end

  @doc "Gives the test its own database transaction until it ends."
  def checkout(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Tldr.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
