defmodule MbtaServer.AlertProcessor.NotificationWorker do
  @moduledoc """
  Worker process for processing a single Notification from SendingQueue
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{SendingQueue, Dispatcher, Model.Notification}
  @type notifications :: [Notification.t]

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @doc false
  def init(state) do
    Process.send_after(self(), :notification, 10)
    {:ok, state}
  end

  @doc """
  Checks sending queue for alert and sends it out to user
  """
  def handle_info(:notification, state) do
    case SendingQueue.pop do
      {:ok, %Notification{} = notification} ->
        Dispatcher.send_notification(notification)
        send(self(), :notification)
      :error ->
        Process.send_after(self(), :notification, 100)
    end
    {:noreply, state}
  end
  def handle_info(_, state) do
    {:noreply, state}
  end
end
