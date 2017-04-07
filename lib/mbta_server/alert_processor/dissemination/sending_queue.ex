defmodule MbtaServer.AlertProcessor.SendingQueue do
  @moduledoc """
  Queue for holding messages ready to be sent
  """
  use GenServer
  alias MbtaServer.AlertProcessor.Model.AlertMessage

  @type message :: AlertMessage.t

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Adds message to qeue
  """
  @spec enqueue(message) :: {atom, atom}
  def enqueue(message) do
    case message do
      %AlertMessage{} ->
        GenServer.call(__MODULE__, {:push, message})
      _ -> {:reply, :no_update}
    end
  end

  @doc """
  Returns message from queue
  """
  @spec pop() :: message
  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  @doc false
  def handle_call(:pop, _from, []) do
    {:reply, nil, []}
  end
  def handle_call(:pop, _from, messages) do
    [message | newstate] = messages
    {:reply, message, newstate}
  end

  @doc false
  def handle_call({:push, message}, _from, messages) do
    newstate = [message | messages]
    {:reply, :success, newstate}
  end

  @doc false
  def handle_call(request, from, state) do
    super(request, from, state)
  end
end
