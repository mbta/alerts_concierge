defmodule MbtaServer.AlertProcessor.HoldingQueue do
  @moduledoc """
  Parent service to handle queuing of incoming messages
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{SendingQueue, Model}
  alias Model.AlertMessage

  @filter_interval Application.get_env(:mbta_server, __MODULE__)[:filter_interval]

  @type message :: AlertMessage.t

  @doc false
  def start_link(messages \\ []) do
    GenServer.start_link(__MODULE__, messages, [name: __MODULE__])
  end

  defp filter_queue(messages) do
    now = DateTime.utc_now()

    {ready_to_send, state} = messages
    |> Enum.split_with(&send_message?(&1, now))

    ready_to_send
    |> Enum.each(fn(message) ->
      SendingQueue.enqueue(message)
    end)

    state
  end

  defp send_message?(message, now) do
    DateTime.compare(Map.get(message, :send_after), now) != :gt
  end

  @doc """
  Add message to holding queue or add to sending queue as appropriate based on date
  """
  @spec enqueue(message) :: {atom, atom}
  def enqueue(message) do
    case send_message?(message, DateTime.utc_now()) do
      true ->
        SendingQueue.enqueue(message)
      false ->
        GenServer.call(__MODULE__, {:push, message})
    end
  end

  @doc """
  Returns message from queue
  """
  @spec pop() :: message
  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  ## Callbacks

  def handle_call(:pop, _from, []) do
    {:reply, nil, []}
  end
  def handle_call(:pop, _from, messages) do
    [message | newstate] = messages
    {:reply, message, newstate}
  end
  def handle_call({:push, message}, _from, messages) do
    newstate = [message | messages]
    {:reply, :success, newstate}
  end
  def handle_call(request, from, state) do
    super(request, from, state)
  end

  @doc """
  Schedule recurring check of queue
  """
  def init(state) do
    send(self(), :schedule)
    {:ok, state}
  end

  @doc """
  Check queue for any messages that can be moved, then schedule another check
  """
  def handle_info(:schedule, queue) do
    state = filter_queue(queue)
    Process.send_after(self(), :schedule, @filter_interval)
    {:noreply, state}
  end
end
