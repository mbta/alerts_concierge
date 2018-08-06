defmodule AlertProcessor.Scheduler do
  @moduledoc """
  Takes alert and subscriptions payload from rules engine and schedules notifications
  """

  alias AlertProcessor.{Model, SendingQueue, NotificationBuilder}
  alias Model.{Alert, Notification, Subscription, User}

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
    # Save notification in the database before adding to sending queue.
    # Do this now in case we re-match the same notificaiton before finishing
    # sending from a previous iteration.

    notifications =
      Enum.map(notifications, fn notification ->
        case Notification.save(notification, :sent) do
          {:ok, notification} ->
            notification

          _ ->
            # Ignore any notification we are unable to save
            # e.g. the associated user record does not exist
            nil
        end
      end)

    SendingQueue.list_enqueue(notifications)
    notifications
  end
end
