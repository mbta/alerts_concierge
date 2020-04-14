defmodule AlertProcessor.NotificationWorker do
  @moduledoc """
  Worker process for processing a single Notification from SendingQueue
  """
  use GenServer
  require Logger

  alias AlertProcessor.{
    SendingQueue,
    Dispatcher,
    Model.Notification
  }

  @type notifications :: [Notification.t()]

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, UUID.uuid4(), opts)
  end

  @doc false
  def init(id) do
    log(id, "event=startup")
    Process.send_after(self(), :notification, 10)
    {:ok, id}
  end

  @doc """
  Checks sending queue for alert and sends it out to user
  """
  def handle_info(:notification, id) do
    pop_start = now()

    case SendingQueue.pop() do
      {:ok, %Notification{} = notification} ->
        log(id, "event=pop result=ok notification=#{notification.id} time=#{now() - pop_start}")

        send_start = now()
        Dispatcher.send_notification(notification)
        log(id, "event=send notification=#{notification.id} time=#{now() - send_start}")

        Process.send(self(), :notification, [])

      :error ->
        log(id, "event=pop result=error time=#{now() - pop_start}")
        Process.send_after(self(), :notification, 100)
    end

    {:noreply, id}
  rescue
    exception ->
      log(id, "event=crash")
      reraise exception, System.stacktrace()
  end

  def handle_info(_, id) do
    {:noreply, id}
  end

  defp log(id, message) do
    Logger.info("worker_log id=#{id} #{message}")
  end

  defp now() do
    System.monotonic_time(:microsecond)
  end
end
