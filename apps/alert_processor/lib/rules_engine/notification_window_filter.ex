defmodule AlertProcessor.NotificationWindowFilter do
  @moduledoc """
  Filters subscriptions by their notification window. If the current day and
  time is within the subscription's notification window, then the subscription
  is filtered through.

  A subscription's notificaiton window has a start time and an end time:

  * A subscription's notification window start time is equal to the
  subscription's `start_time` minus the `alert_time_difference_in_minutes`
  (column in the trips table).

  * A subscription's notification window end time is equal to the
  subscription's `end_time`.

  """

  alias AlertProcessor.Model.Subscription

  @doc """
  Accepts a list of subscriptions and returns a filtered list of subscriptions
  that could be notified on a given day and time per their notification window.

  *Important Note:* Subscriptions are expected to have their trip preloaded.

  """
  @spec filter([Subscription.t], DateTime.t) :: [Subscription.t]
  def filter(subscriptions, now \\ Calendar.DateTime.now!("America/New_York")) do
    Enum.filter(subscriptions, fn(subscription) ->
      within_notification_window?(subscription, now)
    end)
  end

  @doc false
  @spec within_notification_window?(Subscription.t, DateTime.t) :: boolean
  def within_notification_window?(subscription, now) do
    start_time = notification_window_start_time(subscription)
    end_time = subscription.end_time
    multiday? = span_multiple_days?(start_time, end_time)

    day_of_week(now) in relevant_days(subscription)
    && time_within_notification_window?(subscription, start_time, end_time, now, multiday?)
  end

  defp day_of_week(now) do
    now |> DateTime.to_date() |> Date.day_of_week()
  end

  defp relevant_days(subscription) do
    days = %{
      monday: 1,
      tuesday: 2,
      wednesday: 3,
      thursday: 4,
      friday: 5,
      saturday: 6,
      sunday: 7
    }
    Enum.map(subscription.relevant_days, &Map.get(days, &1))
  end

  defp span_multiple_days?(start_time, end_time), do: Time.compare(start_time, end_time) in [:gt, :eq]

  defp time_within_notification_window?(%Subscription{type: :accessibility}, _, _, _, _) do
    # For subscriptions with type of `:accessibility` it doesn't matter what
    # time of the day it is. The users these subscriptions belong to signed up
    # to be notified of specific accessibility related alerts, so regardless of
    # what time of the day it might be, these users should be notified.
    true
  end

  defp time_within_notification_window?(subscription, start_time, end_time, now, true) do
    time_within_notification_window?(subscription, start_time, ~T[23:59:59], now, false)
    || time_within_notification_window?(subscription, ~T[00:00:00], end_time, now, false)
  end
  defp time_within_notification_window?(_subscription, start_time, end_time, now, false) do
    time_now = DateTime.to_time(now)
    start_time_ok? = Time.compare(time_now, start_time) in [:gt, :eq]
    end_time_ok? = Time.compare(time_now, end_time) in [:lt, :eq]
    start_time_ok? && end_time_ok?
  end

  defp notification_window_start_time(subscription) do
    difference_in_minutes = subscription.trip.alert_time_difference_in_minutes
    difference_in_seconds = difference_in_minutes * 60
    Time.add(subscription.start_time, -difference_in_seconds)
  end
end
