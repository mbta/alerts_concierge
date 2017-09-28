defmodule AlertProcessor.NotificationBuilder do
  @moduledoc """
  Responsible for construction of Notifications from an Alert and Subscription
  """

  alias AlertProcessor.Model.{Alert, Notification, Subscription, User}
  alias Calendar.Time, as: T
  alias Calendar.DateTime, as: DT

  @notification_time 86_400

  @doc """
  Given a single subsciption, for each active_period in a given alert:
  1. Build notification with alert and user info
  2. Determine what time the notification should go out (send_after)
  3a. Determine whether or not to send notification based on user's vacation period
  3b. If vacation period overlaps send_after, adjust send_after to end of period
  4a. Determine whether a notification should go out based on a user's do_not_disturb
  4b. If do_not_disturb overlaps send_after, adjust send_after to end of period
  """
  @spec build_notifications(Subscription.t, Alert.t, DateTime.t)
  :: [Notification.t]
  def build_notifications({user, subscriptions}, %Alert{active_period: ap} = alert, now) do
    Enum.reduce(ap, [], fn(active_period, result) ->
      case calculate_send_after(user, {active_period.start, active_period.end}, now) do
        {:error, _} ->
          result
        %DateTime{} = time ->
          notification = %Notification{
              alert_id: alert.id,
              user: user,
              header: alert.header,
              service_effect: alert.service_effect,
              description: alert.description,
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
  }, active_period, now) do

    with :ok <- not_expired(active_period, now),
      {:ok, send_time} <- send_immediately(active_period, now),
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

  @spec send_immediately({DateTime.t, DateTime.t | nil}, DateTime.t)
  :: {:ok, DateTime.t}
  defp send_immediately({start_time, _}, now) do
    sending_time = DT.subtract!(start_time, @notification_time)
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

  defp before_or_equal(first_dt, second_dt) do
    !DT.after?(first_dt, second_dt)
  end
end
