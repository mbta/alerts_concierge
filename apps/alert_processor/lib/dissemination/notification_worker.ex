defmodule AlertProcessor.NotificationWorker do
  @moduledoc """
  Worker process for processing a single Notification from SendingQueue
  """
  use GenServer
  require Logger
  alias AlertProcessor.{SendingQueue, Dispatcher, Model.Notification, RateLimiter, Helpers.ConfigHelper}
  @type notifications :: [Notification.t]

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
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
        send_notification(notification)
        Process.send_after(self(), :notification, send_rate())
      :error ->
        Process.send_after(self(), :notification, 100)
    end
    {:noreply, state}
  end
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp send_notification(notification) do
    with :ok <- RateLimiter.check_rate_limit(notification.user.id),
      {:ok, _} <- Dispatcher.send_notification(notification) do
    else
      {:error, :rate_exceeded} -> Logger.warn("Sending rate exceeded for user: #{notification.user.id}")
    end
  end

  defp send_rate do
    ConfigHelper.get_int(:send_rate)
  end
end
