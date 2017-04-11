defmodule MbtaServer.AlertProcessor.HoldingQueue do
  @moduledoc """
  Parent service to handle queuing of incoming messages
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{Model}
  alias Model.AlertMessage

  @type messages :: [AlertMessage.t]

  @doc false
  def start_link(messages \\ []) do
    GenServer.start_link(__MODULE__, messages, [name: __MODULE__])
  end

  @doc """
  Updates state to AlertMessages that can't be sent yet, returns ones that are ready.
  """
  @spec messages_to_send(DateTime.t | nil) :: {:ok, messages}
  def messages_to_send(now \\ nil) do
    now = now || DateTime.utc_now()
    GenServer.call(__MODULE__, {:filter, now})
  end

  @doc """
  Add message to holding queue
  """
  @spec enqueue(AlertMessage.t) :: :ok
  def enqueue(%AlertMessage{} = message) do
    GenServer.call(__MODULE__, {:push, message})
  end

  @doc """
  Returns message from queue
  """
  @spec pop() :: AlertMessage.t | :error
  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  defp send_message?(message, now) do
    DateTime.compare(message.send_after, now) != :gt
  end

  ## Callbacks

  def handle_call(:pop, _from, []) do
    {:reply, :error, []}
  end
  def handle_call(:pop, _from, messages) do
    [message | newstate] = messages
    {:reply, {:ok, message}, newstate}
  end
  def handle_call({:push, message}, _from, messages) do
    newstate = [message | messages]
    {:reply, :ok, newstate}
  end
  def handle_call({:filter, now}, _from, messages) do
    {ready_to_send, newstate} = messages
    |> Enum.split_with(&send_message?(&1, now))
    {:reply, {:ok, ready_to_send}, newstate}
  end
  def handle_call(request, from, state) do
    super(request, from, state)
  end

  @doc """
  Schedule recurring check of queue
  """
  def init(state) do
    {:ok, state}
  end
end
