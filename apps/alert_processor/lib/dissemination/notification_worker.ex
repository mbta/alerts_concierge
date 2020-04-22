defmodule AlertProcessor.NotificationWorker do
  @moduledoc """
  Worker process for processing a single Notification from SendingQueue
  """
  use GenServer
  require Logger

  alias AlertProcessor.{
    SendingQueue,
    Dissemination.NotificationSender,
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
        log(id, notification, "event=pop time=#{now() - pop_start}")

        send_start = now()
        NotificationSender.send(notification)
        log(id, notification, "event=send time=#{now() - send_start}")

        Process.send(self(), :notification, [])

      :error ->
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
