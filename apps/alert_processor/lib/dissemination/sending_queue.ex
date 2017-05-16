defmodule AlertProcessor.SendingQueue do
  @moduledoc """
  Queue for holding notifications ready to be sent
  """
  use GenServer
  alias AlertProcessor.Model.Notification

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Adds notification to qeue
  """
  @spec enqueue(Notification.t) :: :ok
  def enqueue(%Notification{} = notification) do
    GenServer.call(__MODULE__, {:push, notification})
  end

  @doc """
  Returns notification from queue
  """
  @spec pop() :: {:ok, Notification.t} | :error
  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  @doc false
  def handle_call(:pop, _from, []) do
    {:reply, :error, []}
  end
  def handle_call(:pop, _from, notifications) do
    [notification | newstate] = notifications
    {:reply, {:ok, notification}, newstate}
  end

  @doc false
  def handle_call({:push, notification}, _from, notifications) do
    newstate = [notification | notifications]
    {:reply, :ok, Enum.uniq(newstate)}
  end

  @doc false
  def handle_call(request, from, state) do
    super(request, from, state)
  end
end
