defmodule MbtaServer.AlertProcessor.Scheduler do
  @moduledoc """
  Takes alert and subscriptions payload from rules engine and schedules notifications
  """

  alias MbtaServer.{AlertProcessor, User}
  alias AlertProcessor.{Model, HoldingQueue}
  alias Model.{Alert, Notification, Subscription}
  alias Calendar.Time, as: T
  alias Calendar.DateTime, as: DT
  alias DT.Parse

  @notification_time 86_400

  @doc """
  1. Generate a Notification for each Subscription/Alert combination
  2. Determine what time the notification should go out (send_after)
  3a. Determine whether or not to send notification based on user's vacation period
  3b. If vacation period overlaps send_after, adjust send_after to end of period
  4a. Determine whether a notification should go out based on a user's do_not_disturb
  4b. If do_not_disturb overlaps send_after, adjust send_after to end of period
  5. Add resulting list of Notifications to holding queue
  """
  @spec schedule_notifications({:ok, [any()], Alert.t}, DateTime.t)
  :: {:ok, [Notification.t]} | :error
  def schedule_notifications({:ok, subscription_ids, alert}, now \\ nil) do
    now = now || DateTime.utc_now()

    notifications = subscription_ids
    |> Subscription.fetch_with_user
    |> Enum.flat_map(&build_notifications(&1, alert, now))

    enqueue_notifications(notifications)
    {:ok, notifications}
  end

  @spec enqueue_notifications([Notification.t]) :: :ok
  defp enqueue_notifications(notifications) do
    Enum.each(notifications, &HoldingQueue.enqueue/1)
  end

  @spec build_notifications(Subscription.t, Alert.t, DateTime.t)
  :: [Notification.t]
  defp build_notifications(%Subscription{user: user}, %Alert{active_period: ap} = alert, now) do
    Enum.reduce(ap, [], fn(active_period, result) ->
      {:ok, start_time} = Parse.rfc3339_utc(active_period.start)

      {:ok, end_time} = case active_period.end do
        nil -> {:ok, nil}
        _ -> Parse.rfc3339_utc(active_period.end)
      end

      case calculate_send_after(user, {start_time, end_time}, now) do
        nil ->
          result
        %DateTime{} = time ->
          notification = %Notification{
              alert_id: alert.id,
              user_id: user.id,
              header: alert.header,
              phone_number: user.phone_number,
              email: user.email,
              status: :unsent,
              send_after: time
            }
          [notification | result]
      end
    end)
  end

  @spec calculate_send_after(User.t, {DateTime.t, DateTime.t | nil}, DateTime.t)
  :: DateTime.t | nil
  defp calculate_send_after(%User{
      vacation_start: vs,
      vacation_end: ve,
      do_not_disturb_start: dnd_start,
      do_not_disturb_end: dnd_end
  }, active_period, now) do

    with :ok <- check_expired(active_period, now),
      {:ok, send_time} <- check_send_immediately(active_period, now),
      {:ok, send_time} <- check_vacation_period(active_period, send_time, vs, ve),
      {:ok, send_time} <- check_do_not_disturb(active_period, send_time, dnd_start, dnd_end)
    do
      send_time
    else
      _ -> nil
    end
  end

  @spec check_expired({DateTime.t, DateTime.t | nil}, DateTime.t)
  :: :error | :ok
  defp check_expired({_start_time, nil}, _now), do: :ok
  defp check_expired({_start_time, end_time}, now) do
    case DT.after?(now, end_time) do
      true -> :error
      false -> :ok
    end
  end

  @spec check_send_immediately({DateTime.t, DateTime.t | nil}, DateTime.t)
  :: {:ok, DateTime.t}
  defp check_send_immediately({start_time, _}, now) do
    sending_time = DT.subtract!(start_time, @notification_time)
    case DT.after?(now, sending_time) do
      true -> {:ok, now}
      false -> {:ok, sending_time}
    end
  end

  @spec check_vacation_period({DateTime.t, DateTime.t | nil}, DateTime.t,
  DateTime.t | nil, DateTime.t | nil)
  :: :error | {:ok, DateTime.t}
  defp check_vacation_period({_start_time, _end_time}, sending_time, nil, nil) do
    {:ok, sending_time}
  end
  defp check_vacation_period({_start_time, end_time}, sending_time, vs, ve) do
    case in_vacation_period?(sending_time, end_time, vs, ve) do
      true -> :error
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

  @spec check_do_not_disturb({DateTime.t, DateTime.t | nil}, DateTime.t,
  Time.t | nil, Time.t | nil) :: :error | {:ok, DateTime.t}
  defp check_do_not_disturb({_start_time, _end_time}, sending_time, nil, nil) do
    {:ok, sending_time}
  end
  defp check_do_not_disturb({_start_time, end_time}, send_time, dnd_start, dnd_end) do
    dnd_start = time_to_datetime(dnd_start, send_time)
    dnd_end = time_to_datetime(dnd_end, send_time)
    case check_send_time(send_time, dnd_start, dnd_end) do
      {:ok, send_time} -> {:ok, send_time}
      {:check_send, adjusted_send_time} ->
        case check_end_time(adjusted_send_time, end_time) do
          true -> {:ok, adjusted_send_time}
          false -> :error
        end
    end
  end

  @spec check_end_time(DateTime.t, DateTime.t | nil) :: boolean()
  defp check_end_time(_, nil) do
    true
  end
  defp check_end_time(send_time, end_time) do
    !DT.after?(send_time, end_time)
  end

  @spec check_send_time(DateTime.t, DateTime.t, DateTime.t)
  :: {:ok | :check_send, DateTime.t}
  defp check_send_time(send_time, dnd_start, dnd_end) do
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
    DT.from_date_and_time_and_zone!(erl_date, erl_time, "Etc/UTC")
  end

  defp before_or_equal(first_dt, second_dt) do
    !DT.after?(first_dt, second_dt)
  end
end
