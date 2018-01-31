defmodule AlertProcessor.NotificationBuilder do
  @moduledoc """
  Responsible for construction of Notifications from an Alert and Subscription
  """

  alias AlertProcessor.{Model, Helpers.DateTimeHelper, TextReplacement}
  alias Model.{Alert, Notification, Subscription, User}
  alias Calendar.Time, as: T
  alias Calendar.DateTime, as: DT

  @notification_time 86_400

  @doc """
  Given a user and their subscriptions, for each active_period in a given alert:
  1. Build notification with alert and user info
  2. Determine what time the notification should go out (send_after)
  3a. Determine whether or not to send notification based on user's vacation period
  3b. If vacation period overlaps send_after, adjust send_after to end of period
  4a. Determine whether a notification should go out based on a user's do_not_disturb
  4b. If do_not_disturb overlaps send_after, adjust send_after to end of period
  """
  @spec build_notifications({User.t, [Subscription.t]}, Alert.t, DateTime.t)
  :: [Notification.t]
  def build_notifications({user, subscriptions}, %Alert{duration_certainty: {:estimated, estimated_duration}, active_period: [%{start: start_datetime}]} = alert, now) do

    # sorted in order of start time with subscriptions later today and matching relevant day type coming first
    sorted_subscriptions =
      Enum.sort_by(subscriptions, fn(subscription) ->
        subscription_start_datetime = time_to_datetime(subscription.start_time, now)
        {
          DateTime.compare(subscription_start_datetime, now) == :lt,
          Enum.member?(subscription.relevant_days, AlertProcessor.Helpers.DateTimeHelper.determine_relevant_day_of_week(subscription_start_datetime)),
          DateTime.to_unix(subscription_start_datetime)
        }
      end)

    # get advance notice time for subsequent updates
    advance_notice_in_seconds = Alert.advance_notice_in_seconds(alert)

    # create notifications for all remaining mapping subscriptions for current day
    today_subscriptions =
      Enum.reject(sorted_subscriptions, fn(sub) ->
        Time.compare(sub.start_time, sub.end_time) == :lt && Time.compare(sub.end_time, datetime_to_time(now)) == :lt
      end)
    today_notifications = build_estimated_duration_notifications(user, today_subscriptions, alert, start_datetime, advance_notice_in_seconds)

    tomorrow_notifications = build_estimated_duration_notifications(user, sorted_subscriptions, alert, DT.add!(start_datetime, 86_400), advance_notice_in_seconds)

    day_after_tomorrow_notifications = build_estimated_duration_notifications(user, sorted_subscriptions, alert, DT.add!(start_datetime, 86_400 * 2), advance_notice_in_seconds)

    filter_estimated_duration_notifications_by_estimated_duration(
      today_notifications ++ tomorrow_notifications ++ day_after_tomorrow_notifications,
      estimated_duration
    )
  end
  def build_notifications({user, subscriptions}, alert, now) do
    user
    |> do_build_notifications(subscriptions, alert, now)
    |> Enum.min_by(&DateTime.to_unix(&1.send_after), fn -> [] end)
    |> List.wrap
  end

  defp build_estimated_duration_notifications(user, subscriptions, alert, now, advance_notice_in_seconds) do
    Enum.flat_map(subscriptions, fn(sub) ->
      subscription_start_datetime = time_to_datetime(sub.start_time, now)
      if Enum.member?(sub.relevant_days, DateTimeHelper.determine_relevant_day_of_week(subscription_start_datetime)) do
        do_build_notifications(user, [sub], alert, DT.subtract!(time_to_datetime(sub.start_time, now), advance_notice_in_seconds), 0)
      else
        []
      end
    end)
  end

  defp filter_estimated_duration_notifications_by_estimated_duration(notifications, estimated_duration) do
    notifications
    |> Enum.sort_by(& DateTime.to_unix(&1.send_after))
    |> Enum.reduce([], &add_to_acc_if_not_within_duration(&1, &2, estimated_duration))
  end

  defp add_to_acc_if_not_within_duration(notification, acc, estimated_duration)
  defp add_to_acc_if_not_within_duration(notification, [], _) do
    [notification]
  end
  defp add_to_acc_if_not_within_duration(notification, [previous_notification | _] = acc, estimated_duration) do
    diff = DateTime.to_unix(notification.send_after) - DateTime.to_unix(previous_notification.send_after)
    if diff < estimated_duration do
      acc
    else
      [notification | acc]
    end
  end

  defp do_build_notifications(user, subscriptions, %Alert{active_period: ap} = alert, now, notification_time \\ @notification_time) do
    Enum.reduce(ap, [], fn(active_period, result) ->
      case calculate_send_after(user, {active_period.start, active_period.end}, now, notification_time) do
        {:error, _} ->
          result
        %DateTime{} = time ->
          alert = TextReplacement.replace_text(alert, subscriptions)
          notification = %Notification{
              alert_id: alert.id,
              user: user,
              header: alert.header,
              service_effect: alert.service_effect,
              description: alert.description,
              url: alert.url,
              phone_number: user.phone_number,
              email: user.email,
              status: :unsent,
              send_after: time,
              last_push_notification: alert.last_push_notification,
              alert: alert,
              notification_subscriptions: Enum.map(subscriptions, & %AlertProcessor.Model.NotificationSubscription{subscription_id: &1.id})
            }
          [notification | result]
      end
    end)
  end

  @spec calculate_send_after(User.t, {DateTime.t, DateTime.t | nil}, DateTime.t)
  :: DateTime.t | {:error, atom}
  def calculate_send_after(%User{
      vacation_start: vs,
      vacation_end: ve,
      do_not_disturb_start: dnd_start,
      do_not_disturb_end: dnd_end
  }, {active_start, active_end}, now, notification_time \\ @notification_time) do

    with active_period <- {convert_active_period_to_utc(active_start), convert_active_period_to_utc(active_end)},
      :ok <- not_expired(active_period, now),
      {:ok, send_time} <- send_immediately(active_period, now, notification_time),
      {:ok, send_time} <- outside_vacation_dates(active_period, send_time, vs, ve),
      {:ok, send_time} <- outside_do_not_disturb(active_period, send_time, dnd_start, dnd_end)
    do
      send_time
    else
      error -> error
    end
  end

  @spec not_expired({DateTime.t, DateTime.t | nil}, DateTime.t)
  :: :error | :ok
  defp not_expired({_start_time, nil}, _now), do: :ok
  defp not_expired({_start_time, end_time}, now) do
    if DT.after?(now, end_time) do
      {:error, :expired}
    else
      :ok
    end
  end

  @spec send_immediately({DateTime.t, DateTime.t | nil}, DateTime.t, integer)
  :: {:ok, DateTime.t}
  defp send_immediately({start_time, _}, now, notification_time) do
    sending_time = DT.subtract!(start_time, notification_time)
    if DT.after?(now, sending_time) do
      {:ok, now}
    else
      {:ok, sending_time}
    end
  end

  @spec outside_vacation_dates({DateTime.t, DateTime.t | nil}, DateTime.t,
  DateTime.t | nil, DateTime.t | nil)
  :: :error | {:ok, DateTime.t}
  defp outside_vacation_dates({_start_time, _end_time}, sending_time, nil, nil) do
    {:ok, sending_time}
  end
  defp outside_vacation_dates({_start_time, end_time}, sending_time, vs, ve) do
    case in_vacation_period?(sending_time, end_time, vs, ve) do
      true -> {:error, :vacation}
      false ->
        case DT.after?(sending_time, ve) do
          true -> {:ok, sending_time}
          false -> {:ok, ve}
        end
    end
  end

  @spec in_vacation_period?(DateTime.t, DateTime.t | nil, DateTime.t | nil,
  DateTime.t | nil) :: boolean()
  defp in_vacation_period?(_sending_time, nil, _vacation_start, _vacation_end), do: false
  defp in_vacation_period?(sending_time, end_time, vs, ve) do
    !DT.before?(sending_time, vs) && !DT.after?(end_time, ve)
  end

  @spec outside_do_not_disturb({DateTime.t, DateTime.t | nil}, DateTime.t,
  Time.t | nil, Time.t | nil) :: :error | {:ok, DateTime.t}
  defp outside_do_not_disturb({_start_time, _end_time}, sending_time, nil, nil) do
    {:ok, sending_time}
  end
  defp outside_do_not_disturb({_start_time, end_time}, send_time, dnd_start, dnd_end) do
    dnd_start = time_to_datetime(dnd_start, send_time)
    dnd_end = time_to_datetime(dnd_end, send_time)
    case send_time(send_time, dnd_start, dnd_end) do
      {:ok, send_time} -> {:ok, send_time}
      {:check_send, adjusted_send_time} ->
        case end_time(adjusted_send_time, end_time) do
          true -> {:ok, adjusted_send_time}
          false -> {:error, :do_not_disturb}
        end
    end
  end

  @spec end_time(DateTime.t, DateTime.t | nil) :: boolean()
  defp end_time(_, nil) do
    true
  end
  defp end_time(send_time, end_time) do
    !DT.after?(send_time, end_time)
  end

  @spec send_time(DateTime.t, DateTime.t, DateTime.t)
  :: {:ok | :check_send, DateTime.t}
  defp send_time(send_time, dnd_start, dnd_end) do
    if before_or_equal(dnd_start, dnd_end) do
      if before_or_equal(dnd_start, send_time)
      && before_or_equal(send_time, dnd_end) do
        {:check_send, dnd_end}
      else
        {:ok, send_time}
      end
    else
      case before_or_equal(send_time, dnd_start) do
        true ->
          case before_or_equal(dnd_end, send_time) do
            false -> {:check_send, dnd_end}
            true -> {:ok, send_time}
          end
        false ->
          {:check_send, DT.add!(dnd_end, 86_400)}
      end
    end
  end

  @spec time_to_datetime(Time.t | nil, DateTime.t) :: DateTime.t | nil
  defp time_to_datetime(time, datetime) do
    erl_time = T.to_erl(time)
    erl_date = DT.to_date(datetime)

    erl_date
    |> DT.from_date_and_time_and_zone!(erl_time, "America/New_York")
    |> DT.shift_zone!("Etc/UTC")
  end

  @spec datetime_to_time(DateTime.t) :: Time.t
  defp datetime_to_time(datetime) do
    datetime
    |> DT.shift_zone!("America/New_York")
    |> DateTime.to_time
  end

  defp before_or_equal(first_dt, second_dt) do
    !DT.after?(first_dt, second_dt)
  end

  @spec convert_active_period_to_utc(DateTime.t | nil) :: DateTime.t | nil
  defp convert_active_period_to_utc(nil), do: nil
  defp convert_active_period_to_utc(datetime), do: DT.shift_zone!(datetime, "Etc/UTC")
end
