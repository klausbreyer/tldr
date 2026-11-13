defmodule Tldr.Job do
  @moduledoc """
  One summary that runs apart from the page that asked for it.

  Safari on a phone freezes a page in the background and drops its
  connection, which ends the page's process. The job goes on and keeps its
  summary in `Tldr.Cache`. When the page comes back it asks again and finds
  the summary there, or joins the running job. There is one job per address
  and language, so readers who ask at the same time share it
  (`docs/decisions/013`).
  """

  use GenServer, restart: :temporary

  alias Tldr.{Cache, Language, Source, Summarizer}

  @registry Tldr.Job.Registry
  @supervisor Tldr.Job.Supervisor

  @doc """
  Summarizes `address` like `Tldr.Summarizer.summarize/2`, from the cache
  when it can. The third element is the time the cached summary was saved,
  or nil for a new one. `fresh: true` skips the cache. The other `opts` go
  to the summarizer.
  """
  @spec summarize(String.t(), keyword()) ::
          {:ok, Tldr.Summary.t(), DateTime.t() | nil} | {:error, term()}
  def summarize(address, opts \\ []) do
    {fresh, opts} = Keyword.pop(opts, :fresh, false)
    opts = Keyword.put_new(opts, :language, Language.default())

    with {:ok, {_kind, url}} <- Source.parse(address) do
      case if(fresh, do: :miss, else: Cache.fetch(url, opts[:language])) do
        {:ok, summary, saved} -> {:ok, summary, saved}
        :miss -> await(url, opts)
      end
    end
  end

  defp await(url, opts) do
    # The callers let test stubs (Req.Test) and the test database reach the
    # job's outside calls.
    callers = [self() | Process.get(:"$callers", [])]
    child = {__MODULE__, {url, opts, callers}}

    pid =
      case DynamicSupervisor.start_child(@supervisor, child) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    GenServer.call(pid, :await, :infinity)
  catch
    # The job ended between finding it and asking it. Its summary is in the
    # cache now, or it failed and runs again.
    :exit, {reason, {GenServer, :call, _}} when reason in [:noproc, :normal] ->
      summarize(url, opts)
  end

  @doc false
  def start_link({url, opts, callers}) do
    GenServer.start_link(__MODULE__, {url, opts, callers},
      name: {:via, Registry, {@registry, {url, opts[:language]}}}
    )
  end

  @impl true
  def init({url, opts, callers}) do
    Process.put(:"$callers", callers)

    %{ref: ref} =
      Task.async(fn ->
        with {:ok, summary} <- Summarizer.summarize(url, opts) do
          Cache.put(summary, opts[:language])
          {:ok, summary, nil}
        end
      end)

    {:ok, %{task: ref, waiting: []}}
  end

  @impl true
  def handle_call(:await, from, state), do: {:noreply, %{state | waiting: [from | state.waiting]}}

  # A crash of the task ends the job too: they are linked, and the
  # waiting callers get the exit.
  @impl true
  def handle_info({ref, result}, %{task: ref} = state) do
    Process.demonitor(ref, [:flush])
    Enum.each(state.waiting, &GenServer.reply(&1, result))
    {:stop, :normal, state}
  end
end
