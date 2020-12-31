defmodule AlertProcessor.SendingQueue do
  @moduledoc "Queue process for distributing notifications to sending workers."

  use GenServer
  alias AlertProcessor.Model.Notification

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, :queue.new(), opts)
  end

  def init(state), do: {:ok, state}

  @doc "Get the number of notifications in the queue."
  @spec length() :: non_neg_integer
  def length(name \\ __MODULE__) do
    GenServer.call(name, :length)
  end

  @doc "Remove and return a notification from the queue."
  @spec pop() :: {:ok, Notification.t()} | :error
  def pop(name \\ __MODULE__) do
    GenServer.call(name, :pop)
  end

  @doc "Add a notification to the queue."
  @spec push(Notification.t()) :: :ok
  def push(name \\ __MODULE__, %Notification{} = notification) do
    GenServer.call(name, {:push, notification})
  end

  @doc "Add a list of notifications to the queue in list order."
  @spec push_list([Notification.t()]) :: :ok
  def push_list(name \\ __MODULE__, notifications) when is_list(notifications) do
    GenServer.call(name, {:push_list, notifications})
  end

  @doc "Drop all notifications from the queue."
  @spec reset() :: :ok
  def reset(name \\ __MODULE__) do
    GenServer.call(name, :reset)
  end

  def handle_call(:length, _from, queue) do
    {:reply, :queue.len(queue), queue}
  end

  def handle_call(:pop, _from, queue) do
    case :queue.out(queue) do
      {:empty, _} -> {:reply, :error, queue}
      {{:value, notification}, new_queue} -> {:reply, {:ok, notification}, new_queue}
    end
  end

  def handle_call({:push, notification}, _from, queue) do
    {:reply, :ok, :queue.in(notification, queue)}
  end

  def handle_call({:push_list, notifications}, _from, queue) do
    {:reply, :ok, Enum.reduce(notifications, queue, &:queue.in(&1, &2))}
  end

  def handle_call(:reset, _from, _notifications) do
    {:reply, :ok, :queue.new()}
  end
end
