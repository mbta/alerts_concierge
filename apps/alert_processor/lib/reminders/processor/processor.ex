defmodule AlertProcessor.Reminders.Processor do
  @moduledoc """
  Responsible for processing reminders for a list of alerts.

  """

  alias AlertProcessor.Reminders.Processor.SubscriptionsToRemind

  alias AlertProcessor.Model.{
    Alert,
    Notification
  }

  alias AlertProcessor.{
    SendingQueue,
    NotificationBuilder
  }

  @doc """
  Schedules reminders due for a given list of alerts.

  It schedules reminders by following these steps:

  1. Getting the latest notifications for the given alerts
  2. Determining which of the notifications are due for a reminder
  3. Building reminder notifications
  4. Scheduling/enqueueing reminder notifications

  """
  @spec process_alerts([Alert.t()], DateTime.t()) :: :ok
  def process_alerts(alerts, now \\ Calendar.DateTime.now!("Etc/UTC")) do
    latest_notifications = Notification.most_recent_for_alerts(alerts)

    for alert <- alerts do
      relevant_notifications = relevant_notifications(latest_notifications, alert)

      {alert, relevant_notifications, now}
      |> SubscriptionsToRemind.perform()
      |> build_notifications(alert)
      |> schedule_notifications()
    end

    :ok
  end

  defp relevant_notifications(notifications, alert) do
    Enum.filter(notifications, &(&1.alert_id == alert.id))
  end

  defp build_notifications(subscriptions, alert) do
    subscriptions
    |> Enum.group_by(& &1.user)
    |> Map.to_list()
    |> Enum.map(&NotificationBuilder.build_notification(&1, alert))
  end

  defp schedule_notifications(notifications) do
    # save notification in the database before adding to sending queue
    # do this now incase we re-match the same notificaiton before finishing
    # sending from a previous iteration
    for notification <- notifications do
      {:ok, _} = Notification.save(notification, :sent)
    end

    SendingQueue.list_enqueue(notifications)
  end
end
