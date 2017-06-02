defmodule AlertProcessor.QueueWorker do
  @moduledoc """
  Worker process for processing Notifications from HoldingQueue
  """
  use GenServer
  alias AlertProcessor.{HoldingQueue, SendingQueue, Model.Notification}
  @type notifications :: [Notification.t]

  @doc false
  def start_link(), do: start_link({HoldingQueue, SendingQueue}, [name: __MODULE__])
  def start_link(queue_names, opts) do
    GenServer.start_link(__MODULE__, queue_names, opts)
  end

  @doc false
  def init(state) do
    Process.send_after(self(), :notification, 10)
    {:ok, state}
  end

  @doc """
  Checks holding queue for any notifications that are ready to send and
  passes them to the sending queue
  """
  def handle_info(:notification, {holding_queue_name, sending_queue_name} = state) do
    case HoldingQueue.notifications_to_send(holding_queue_name) do
      :error ->
        Process.send_after(self(), :notification, 100)
      {:ok, notifications} ->
        send_notifications(sending_queue_name, notifications)
        send(self(), :notification)
    end
    {:noreply, state}
  end

  defp send_notifications(sending_queue_name, notifications) do
    Enum.each(notifications, &SendingQueue.enqueue(sending_queue_name, &1))
  end
end
