defmodule AlertProcessor.HoldingQueue do
  @moduledoc """
  Parent service to handle queuing of incoming notifications
  """
  use GenServer
  alias AlertProcessor.Model.Notification

  @type notifications :: [Notification.t]

  @doc false
  def start_link(notifications \\ [], opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, Enum.uniq(notifications), opts)
  end

  @doc """
  Updates state to Notifications that can't be sent yet, returns ones that are ready.
  """
  @spec notifications_to_send(atom, DateTime.t | nil) :: {:ok, notifications} | :error
  def notifications_to_send(name \\ __MODULE__)
  def notifications_to_send(name) do
    now = DateTime.utc_now()
    GenServer.call(name, {:filter, now})
  end
  def notifications_to_send(name, now) do
    GenServer.call(name, {:filter, now})
  end

  @doc """
  Add list of notifications to holding queue
  """
  @spec list_enqueue([Notification.t]) :: :ok
  def list_enqueue(name \\ __MODULE__, notifications) do
    GenServer.call(name, {:list_push, notifications})
  end

  @doc """
  Returns notification from queue
  """
  @spec pop() :: Notification.t | :error
  def pop(name \\ __MODULE__) do
    GenServer.call(name, :pop)
  end

  @doc """
  takes list of alert ids to filter out from holding queue's list of notifications
  waiting to be sent.
  """
  @spec remove_notifications([String.t]) :: :ok
  def remove_notifications(name \\ __MODULE__, removed_alert_ids)
  def remove_notifications(_name, []) do
    :ok
  end
  def remove_notifications(name, removed_alert_ids) do
    GenServer.call(name, {:remove, removed_alert_ids})
  end

  @doc """
  take user_id and clears out all notifications waiting to be sent to that user
  """
  @spec remove_user_notifications(String.t) :: :ok
  def remove_user_notifications(name \\ __MODULE__, user_id) do
    GenServer.call(name, {:clear_user, user_id})
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
  def handle_call({:list_push, new_notifications}, _from, notifications) do
    newstate = new_notifications ++ notifications
    {:reply, :ok, Enum.uniq_by(newstate, & {&1.user_id, &1.alert_id, &1.send_after})}
  end
  def handle_call({:remove, removed_alert_ids}, _from, notifications) do
    newstate = Enum.reject(notifications, &Enum.member?(removed_alert_ids, &1.alert_id))
    {:reply, :ok, newstate}
  end
  def handle_call({:filter, now}, _from, notifications) do
    {ready_to_send, newstate} = notifications
    |> Enum.split_with(&send_notification?(&1, now))
    {:reply, {:ok, ready_to_send}, newstate}
  end
  def handle_call({:clear_user, user_id}, _from, notifications) do
    newstate = Enum.reject(notifications, fn(n) -> n.user_id == user_id end)
    {:reply, :ok, newstate}
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
