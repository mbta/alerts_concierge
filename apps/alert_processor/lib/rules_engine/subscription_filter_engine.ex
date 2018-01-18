defmodule AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias AlertProcessor.{ActivePeriodFilter, InformedEntityFilter, Model,
    Repo, Scheduler, SentAlertFilter, SeverityFilter}
  alias Model.{Alert, Notification, Subscription}

  @spec schedule_all_notifications([Alert.t]) :: Keyword.t
  def schedule_all_notifications(alerts) do
    all_subscriptions = Subscription
    |> Repo.all()
    |> Repo.preload(:user)
    |> Repo.preload(:informed_entities)

    notifications = Notification.most_recent_for_subscriptions_and_alerts(all_subscriptions, alerts)

    for alert <- alerts do
      matched_subscriptions = determine_recipients(alert, all_subscriptions, notifications)
      schedule_distinct_notifications(alert, matched_subscriptions)
    end
  end

  @doc """
  determine_recipients/3 receives an alert and applies relevant filters to exclude users who should not be notified
  """
  @spec determine_recipients(Alert.t, [Subscription.t], [Notification.t]) :: [Subscription.t]
  def determine_recipients(alert, subscriptions, notifications) do
    {subscriptions_to_test, subscriptions_to_auto_resend} = SentAlertFilter.filter(subscriptions,
                                                                                   alert: alert,
                                                                                   notifications: notifications)
    subscriptions_to_test
    |> InformedEntityFilter.filter(alert: alert)
    |> SeverityFilter.filter(alert: alert)
    |> ActivePeriodFilter.filter(alert: alert)
    |> Kernel.++(subscriptions_to_auto_resend)
  end

  @spec schedule_distinct_notifications(Alert.t, [Subscription.t]) :: {:ok, [Notification.t]} | :error
  def schedule_distinct_notifications(alert, subscriptions) do
    subscriptions
    |> Enum.group_by(& &1.user)
    |> Map.to_list()
    |> Scheduler.schedule_notifications(alert)
  end
end
