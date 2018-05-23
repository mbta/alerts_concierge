defmodule AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias AlertProcessor.{ActivePeriodFilter, InformedEntityFilter, Model,
    Repo, Scheduler, SentAlertFilter}
  alias Model.{Alert, Notification, Subscription}
  require Logger

  @notification_window_filter Application.get_env(:alert_processor, :notification_window_filter)

  @spec schedule_all_notifications([Alert.t]) :: {integer, Keyword.t}
  def schedule_all_notifications(alerts) do
    all_subscriptions = Subscription
    |> Repo.all()
    |> Repo.preload(:user)
    |> Repo.preload(:informed_entities)
    |> Repo.preload(:trip)

    start_time = Time.utc_now()

    {skipped, matched_notifications} = Enum.reduce(alerts, {0, []}, fn(alert, {last_skipped, existing_notifications}) ->
      case all_subscriptions do
        [] -> {last_skipped + 1, [{:ok, []}] ++ existing_notifications}
        new_subscriptions ->
          notifications = Notification.most_recent_for_subscriptions_and_alerts(new_subscriptions, [alert])
          matched_subscriptions = determine_recipients(alert, new_subscriptions, notifications)
          notifications = schedule_distinct_notifications(alert, matched_subscriptions)
          {last_skipped, [notifications] ++ existing_notifications}
      end
    end)
    Logger.info(fn -> "alert matching, time=#{Time.diff(Time.utc_now(), start_time, :millisecond)}, skipped: #{skipped}" end)
    {skipped, matched_notifications}
  end

  @doc """
  determine_recipients/3 receives an alert and applies relevant filters to exclude users who should not be notified
  """
  @spec determine_recipients(Alert.t, [Subscription.t], [Notification.t], DateTime.t) :: [Subscription.t]
  def determine_recipients(alert, subscriptions, notifications, now \\ Calendar.DateTime.now!("America/New_York")) do
    {subscriptions_to_test, subscriptions_to_auto_resend} =
      SentAlertFilter.filter(subscriptions, alert, notifications, now)

    subscriptions_to_test
    |> @notification_window_filter.filter()
    |> InformedEntityFilter.filter(alert: alert)
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
