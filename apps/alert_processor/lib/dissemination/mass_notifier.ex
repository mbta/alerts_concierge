defmodule AlertProcessor.Dissemination.MassNotifier do
  @moduledoc "Efficiently saves and enqueues many notifications for sending."

  alias AlertProcessor.SendingQueue
  alias AlertProcessor.Model.Notification
  alias AlertProcessor.Repo

  require Logger

  # Save and enqueue notifications in batches equal to (at least) the number of sending workers,
  # so all workers will have something to do while we save the next batch. The test environment
  # sets the number of workers to 0, so we need to ensure the batch size is at least 1.
  @batch_size max(1, Application.fetch_env!(:alert_processor, :notification_workers))

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

    saved_notifications =
      notifications
      |> Stream.chunk_every(@batch_size)
      |> Stream.map(&save_batch/1)
      |> Enum.flat_map(&enqueue_batch/1)

    log("event=finish")

    saved_notifications
  end

  defp save_batch(notifications) do
    batch_start = now()

    {:ok, saved_notifications} =
      Repo.transaction(fn ->
        notifications
        |> Stream.map(fn notification ->
          save_start = now()

          case Notification.save(notification, :sent) do
            {:ok, notification} ->
              log("event=save notification=#{notification.id} time=#{now() - save_start}")
              notification

            {:error, changeset} ->
              Logger.warn("notification insert failed: #{inspect(changeset)}")
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)
      end)

    log("event=commit time=#{now() - batch_start}")
    saved_notifications
  end

  defp enqueue_batch(notifications) do
    enqueue_start = now()
    for n <- notifications, do: SendingQueue.push(n)
    log("event=enqueue time=#{now() - enqueue_start}")
    notifications
  end

  defp log(message) do
    Logger.info("scheduler_log #{message}")
  end

  defp now() do
    System.monotonic_time(:microsecond)
  end
end
