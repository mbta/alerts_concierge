defmodule AlertProcessor.Scheduler do
  @moduledoc """
  Takes alert and subscriptions payload from rules engine and schedules notifications
  """

  alias AlertProcessor.{Model, HoldingQueue, NotificationBuilder}
  alias Model.{Alert, Notification, Subscription, User}

  @doc """
  1. Generate a Notification for each {User, [Subscription]}/Alert combination
  2. Add resulting list of Notifications to holding queue
  """
  @spec schedule_notifications({User.t, [Subscription.t]}, Alert.t, DateTime.t)
  :: {:ok, [Notification.t]} | :error
  def schedule_notifications(user_subscriptions, alert, now \\ nil) do
    now = now || DateTime.utc_now()

    notifications = user_subscriptions
    |> Enum.flat_map(&NotificationBuilder.build_notifications(&1, alert, now))

    enqueue_notifications(notifications)
    {:ok, notifications}
  end

  @spec enqueue_notifications([Notification.t]) :: :ok
  defp enqueue_notifications(notifications) do
    Enum.each(notifications, &HoldingQueue.enqueue/1)
  end
end
