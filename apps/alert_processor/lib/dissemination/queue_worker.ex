defmodule AlertProcessor.QueueWorker do
  @moduledoc """
  Worker process for processing Notifications from HoldingQueue
  """
  use GenServer
  alias AlertProcessor.{HoldingQueue, SendingQueue, Model.Notification}
  @type notifications :: [Notification.t]

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], [])
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
  def handle_info(:notification, state) do
    case HoldingQueue.notifications_to_send() do
      :error ->
        Process.send_after(self(), :notification, 100)
      {:ok, notifications} ->
        send_notifications(notifications)
        send(self(), :notification)
    end
    {:noreply, state}
  end

  defp send_notifications(notifications) do
    Enum.each(notifications, &SendingQueue.enqueue/1)
  end
end
