defmodule Tldr.Job do
  @moduledoc """
  One summary that runs apart from the page that asked for it.

  Safari on a phone freezes a page in the background and drops its
  connection, which ends the page's process. The job goes on. When the
  page comes back it asks again with the same key and joins the running
  job or takes its result. A job ends ten minutes after its last result
  (`docs/decisions/012`).
  """

  use GenServer, restart: :temporary

  alias Tldr.Summarizer

  @registry Tldr.Job.Registry
  @supervisor Tldr.Job.Supervisor
  @keep :timer.minutes(10)

  @doc """
  Summarizes `address` like `Tldr.Summarizer.summarize/2` and waits for the
  result. A second call with the same `key` joins the running job or takes
  its summary. An error runs again, and so does everything with
  `fresh: true`. `opts` other than `:fresh` go to the summarizer.
  """
  @spec summarize(term(), String.t(), keyword()) ::
          {:ok, Tldr.Summary.t()} | {:error, term()}
  def summarize(key, address, opts \\ []) do
    {fresh, summarizer_opts} = Keyword.pop(opts, :fresh, false)
    # The callers let test stubs (Req.Test) reach the job's outside calls.
    callers = [self() | Process.get(:"$callers", [])]
    child = {__MODULE__, {key, address, summarizer_opts, callers}}

    pid =
      case DynamicSupervisor.start_child(@supervisor, child) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    GenServer.call(pid, {:await, fresh}, :infinity)
  catch
    # The job ended between finding it and asking it.
    :exit, {reason, {GenServer, :call, _}} when reason in [:noproc, :normal] ->
      summarize(key, address, opts)
  end

  @doc false
  def start_link({key, address, opts, callers}) do
    GenServer.start_link(__MODULE__, {address, opts, callers},
      name: {:via, Registry, {@registry, key}}
    )
  end

  @impl true
  def init({address, opts, callers}) do
    Process.put(:"$callers", callers)
    {:ok, run(%{address: address, opts: opts, waiting: []})}
  end

  @impl true
  def handle_call({:await, fresh}, from, state) do
    case state.result do
      nil -> {:noreply, %{state | waiting: [from | state.waiting]}}
      {:ok, _summary} = result when not fresh -> {:reply, result, state}
      _again -> {:noreply, %{run(state) | waiting: [from]}}
    end
  end

  # A crash of the task ends the job too: they are linked, and the
  # waiting callers get the exit.
  @impl true
  def handle_info({ref, result}, %{task: ref} = state) do
    Process.demonitor(ref, [:flush])
    Enum.each(state.waiting, &GenServer.reply(&1, result))
    Process.send_after(self(), {:forget, ref}, @keep)
    {:noreply, %{state | result: result, waiting: []}}
  end

  def handle_info({:forget, ref}, %{task: ref} = state), do: {:stop, :normal, state}
  # The timer of a result that a fresh run replaced.
  def handle_info({:forget, _ref}, state), do: {:noreply, state}

  defp run(state) do
    %{ref: ref} = Task.async(fn -> Summarizer.summarize(state.address, state.opts) end)
    Map.merge(state, %{task: ref, result: nil})
  end
end
