defmodule AlertProcessor.SendingQueue do
  @moduledoc """
  Queue for holding notifications ready to be sent
  """
  use GenServer
  alias AlertProcessor.Model.Notification

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Add list of notifications to queue
  """
  @spec list_enqueue([Notification.t]) :: :ok
  def list_enqueue(name \\ __MODULE__, notifications) do
    GenServer.call(name, {:list_push, notifications})
  end

  @doc """
  Adds notification to qeue
  """
  @spec enqueue(Notification.t) :: :ok
  def enqueue(name \\ __MODULE__, %Notification{} = notification) do
    GenServer.call(name, {:push, notification})
  end

  @doc """
  Returns notification from queue
  """
  @spec pop() :: {:ok, Notification.t} | :error
  def pop(name \\ __MODULE__) do
    GenServer.call(name, :pop)
  end

  @doc """
  Resets state to an empty list.

  For use in tests only.
  """
  @spec reset() :: :ok
  def reset(name \\ __MODULE__) do
    GenServer.call(name, :reset)
  end
  
  @doc """
  Returns the number of items in the queue
  """
  def queue_length(name \\ __MODULE__) do
    GenServer.call(name, :queue_length)
  end

  @doc false
  def handle_call({:list_push, new_notifications}, _from, notifications) do
    newstate = new_notifications ++ notifications
    {:reply, :ok, Enum.uniq(newstate)}
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
  def handle_call(:queue_length, _from, notifications) do
    {:reply, {:ok, length(notifications)}, notifications}
  end

  @doc false
  def handle_call({:push, notification}, _from, notifications) do
    newstate = [notification | notifications]
    {:reply, :ok, Enum.uniq(newstate)}
  end

  @doc false
  def handle_call(:reset, _from, _notifications) do
    {:reply, :ok, []}
  end

  @doc false
  def handle_call(request, from, state) do
    super(request, from, state)
  end
end
