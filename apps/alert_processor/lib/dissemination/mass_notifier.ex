defmodule AlertProcessor.Dissemination.MassNotifier do
  @moduledoc "Efficiently saves and enqueues many notifications for sending."

  alias AlertProcessor.SendingQueue
  alias AlertProcessor.Model.Notification

  require Logger

  @doc """
  Saves and enqueues a list of notifications. Returns the saved notifications. Any that fail to
  save are dropped from the returned list and a warning is logged (this is not expected to happen
  except when a user is deleted while processing alerts).

  Notifications must be saved prior to enqueueing, as part of the AlertWorker process, otherwise
  the next run of the AlertWorker would mistakenly think some users had not yet been notified and
  enqueue duplicate notifications for them.
  """
  @spec save_and_enqueue([Notification.t()]) :: [Notification.t()]
  def save_and_enqueue(notifications) do
    log("event=start")

    notifications =
      Enum.map(notifications, fn notification ->
        save_start = now()

        case Notification.save(notification, :sent) do
          {:ok, notification} ->
            log("event=save notification=#{notification.id} time=#{now() - save_start}")

            enqueue_start = now()
            SendingQueue.enqueue(notification)
            log("event=enqueue notification=#{notification.id} time=#{now() - enqueue_start}")

            notification

          {:error, changeset} ->
            Logger.warn("notification insert failed: #{inspect(changeset)}")
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    log("event=finish")

    notifications
  end

  defp log(message) do
    Logger.info("scheduler_log #{message}")
  end

  defp now() do
    System.monotonic_time(:microsecond)
  end
end
