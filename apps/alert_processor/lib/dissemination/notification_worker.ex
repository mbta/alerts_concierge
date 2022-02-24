defmodule AlertProcessor.NotificationWorker do
  @moduledoc """
  Worker process for processing a single Notification from SendingQueue
  """
  use GenServer
  require Logger

  alias AlertProcessor.{
    SendingQueue,
    Dissemination.NotificationSender,
    Model.Notification
  }

  @idle_wait Application.compile_env(:alert_processor, :notification_worker_idle_wait, 1000)

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, UUID.uuid4(), opts)
  end

  @doc false
  def init(id) do
    log(id, "event=startup")
    send(self(), :work)
    {:ok, id}
  end

  @doc """
  Checks the sending queue for a notification. If there is one, sends it and checks for another
  immediately, otherwise checks again after a short delay.
  """
  def handle_info(:work, id) do
    pop_start = now()

    case SendingQueue.pop() do
      {:ok, %Notification{} = notification} ->
        log(id, notification, "event=pop time=#{now() - pop_start}")

        send_start = now()
        NotificationSender.send(notification)
        log(id, notification, "event=send time=#{now() - send_start}")

        send(self(), :work)

      :error ->
        Process.send_after(self(), :work, @idle_wait)
    end

    {:noreply, id}
  rescue
    exception ->
      log(id, "event=crash")
      reraise exception, __STACKTRACE__
  end

  def handle_info(_, id) do
    {:noreply, id}
  end

  defp log(id, notification, message) do
    mode = if(is_nil(notification.phone_number), do: "email", else: "sms")
    Logger.info("worker_log id=#{id} mode=#{mode} notification=#{notification.id} #{message}")
  end

  defp log(id, message) do
    Logger.info("worker_log id=#{id} #{message}")
  end

  defp now() do
    System.monotonic_time(:microsecond)
  end
end
