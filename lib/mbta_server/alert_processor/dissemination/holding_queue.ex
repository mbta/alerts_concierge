defmodule MbtaServer.AlertProcessor.HoldingQueue do
  @moduledoc """
  Parent service to handle queuing of incoming notifications
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{Model}
  alias Model.Notification

  @type notifications :: [Notification.t]

  @doc false
  def start_link(notifications \\ []) do
    GenServer.start_link(__MODULE__, notifications, [name: __MODULE__])
  end

  @doc """
  Updates state to Notifications that can't be sent yet, returns ones that are ready.
  """
  @spec notifications_to_send(DateTime.t | nil) :: {:ok, notifications} | :error
  def notifications_to_send(now \\ nil) do
    now = now || DateTime.utc_now()
    GenServer.call(__MODULE__, {:filter, now})
  end

  @doc """
  Add notification to holding queue
  """
  @spec enqueue(Notification.t) :: :ok
  def enqueue(%Notification{} = notification) do
    GenServer.call(__MODULE__, {:push, notification})
  end

  @doc """
  Returns notification from queue
  """
  @spec pop() :: Notification.t | :error
  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  @doc """
  takes list of alert ids to filter out from holding queue's list of messages
  waiting to be sent.
  """
  @spec remove_notifications([String.t] | []) :: :ok
  def remove_notifications([]) do
    :ok
  end

  def remove_notifications(removed_alert_ids) do
    GenServer.call(__MODULE__, {:remove, removed_alert_ids})
  end

  @doc false
  def remove_notifications([]) do
    :ok
  end

  defp send_notification?(notification, now) do
    DateTime.compare(notification.send_after, now) != :gt
  end

  ## Callbacks

  def handle_call(:pop, _from, []) do
    {:reply, :error, []}
  end
  def handle_call(:pop, _from, notifications) do
    [notification | newstate] = notifications
    {:reply, {:ok, notification}, newstate}
  end
  def handle_call({:push, notification}, _from, notifications) do
    newstate = [notification | notifications]
    {:reply, :ok, newstate}
  end
  def handle_call({:remove, removed_alert_ids}, _from, messages) do
    newstate = Enum.reject(messages, &Enum.member?(removed_alert_ids, &1.alert_id))
    {:reply, :ok, newstate}
  end
  def handle_call({:filter, now}, _from, notifications) do
    {ready_to_send, newstate} = notifications
    |> Enum.split_with(&send_notification?(&1, now))
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
