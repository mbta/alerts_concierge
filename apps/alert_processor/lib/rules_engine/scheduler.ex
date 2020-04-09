defmodule AlertProcessor.Scheduler do
  @moduledoc """
  Takes alert and subscriptions payload from rules engine and schedules notifications
  """

  alias AlertProcessor.{Model, SendingQueue, NotificationBuilder}
  alias Model.{Alert, Notification, Subscription, User}

  require Logger

  @doc """
  1. Generate a Notification for each {User, [Subscription]}/Alert combination
  """
  @spec schedule_notifications({User.t(), [Subscription.t()]}, Alert.t()) ::
          {:ok, [Notification.t()]} | :error
  def schedule_notifications(user_subscriptions, alert) do
    notifications =
      user_subscriptions
      |> Enum.map(&NotificationBuilder.build_notification(&1, alert))

    notifications = enqueue_notifications(notifications)
    {:ok, notifications}
  end

  @spec enqueue_notifications([Notification.t()]) :: [Notification.t()]
  defp enqueue_notifications(notifications) do
    # Insert Notification records and add them to the sending queue. Records must be inserted
    # here, and not within the sending workers, otherwise the next run of the AlertWorker would
    # mistakenly think some users had not yet been notified, and notify them again.

    notifications =
      Enum.map(notifications, fn notification ->
        case Notification.save(notification, :sent) do
          {:ok, notification} ->
            SendingQueue.enqueue(notification)
            notification

          {:error, changeset} ->
            Logger.warn("notification insert failed: #{inspect(changeset)}")
            nil
        end
      end)

    notifications
  end
end
