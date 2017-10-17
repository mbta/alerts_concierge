defmodule AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias AlertProcessor.{ActivePeriodFilter, InformedEntityFilter, Model,
    Repo, Scheduler, SentAlertFilter, SeverityFilter}
  alias Model.{Alert, Notification, Subscription}

  def process_alerts(alerts) do
    subscriptions =
      Subscription
      |> Repo.all()
      |> Repo.preload(:user)
      |> Repo.preload(:informed_entities)

    notifications = Notification.most_recent_for_subscriptions_and_alerts(subscriptions, alerts)

    for alert <- alerts do
      SystemMetrics.Tracer.trace(fn() ->
        process_alert(alert, subscriptions, notifications)
      end, "single_alert_processing")
    end
  end
  @doc """
  process_alert/1 receives an alert and applies relevant filters to send alerts
  to the correct users based on the alert.
  """
  @spec process_alert(Alert.t, [Subscription.t], [Notification.t]) :: {:ok, [Notification.t]} | :error
  def process_alert(alert, subscriptions, notifications) do
    {subscriptions_to_test, subscriptions_to_auto_resend} = SentAlertFilter.filter(subscriptions, alert: alert, notifications: notifications)

    subscriptions_to_send =
      subscriptions_to_test
      |> InformedEntityFilter.filter(alert: alert)
      |> SeverityFilter.filter(alert: alert)
      |> ActivePeriodFilter.filter(alert: alert)

    subscriptions_to_send
    |> Kernel.++(subscriptions_to_auto_resend)
    |> Enum.group_by(& &1.user)
    |> Map.to_list()
    |> Scheduler.schedule_notifications(alert)
  end
end
