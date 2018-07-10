defmodule AlertProcessor.Scheduler do
  @moduledoc """
  Takes alert and subscriptions payload from rules engine and schedules notifications
  """

  alias AlertProcessor.{Model, SendingQueue, NotificationBuilder}
  alias Model.{Alert, Notification, Subscription, User}

  @doc """
  1. Generate a Notification for each {User, [Subscription]}/Alert combination
  """
  @spec schedule_notifications({User.t, [Subscription.t]}, Alert.t)
  :: {:ok, [Notification.t]} | :error
  def schedule_notifications(user_subscriptions, alert) do
    notifications = user_subscriptions
    |> Enum.map(&NotificationBuilder.build_notification(&1, alert))

    enqueue_notifications(notifications)
    {:ok, notifications}
  end

  @spec enqueue_notifications([Notification.t]) :: :ok
  defp enqueue_notifications(notifications) do
    # save notification in the database before adding to sending queue
    # do this now incase we re-match the same notificaiton before finishing
    # sending from a previous iteration
    for notification <- notifications do
      {:ok, _} = Notification.save(notification, :sent)
    end
    SendingQueue.list_enqueue(notifications)
  end
end
