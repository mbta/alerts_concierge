defmodule MbtaServer.AlertProcessor.Scheduler do
  @moduledoc """
  Takes alert and subscriptions payload from rules engine and schedules notifications
  """

  alias MbtaServer.{AlertProcessor, User}
  alias AlertProcessor.{Model, HoldingQueue}
  alias Model.{Alert, Notification, Subscription}

  @notification_time 86_400 # 24 hours as seconds

  @doc """
  Takes alert and list of subscriptions ids
  Generates a notification for each subscription/alert combo
  Filter notificaitons if they should not be sent based on blackout/vacation
  Schedules notifications based on blackout/vacation and adds to holding queue
  """
  @spec schedule_notifications({:ok, list, Alert.t}, DateTime.t) :: :ok
  def schedule_notifications({:ok, subscription_ids, alert}, now \\ nil) do
    now = now || DateTime.utc_now()

    notifications = subscription_ids
    |> Subscription.fetch_with_user
    |> Enum.flat_map(&build_notifications(&1, alert, now))
    |> Enum.reject(fn(alert) -> alert.send_after == nil end)

    enqueue_notifications(notifications)
    {:ok, notifications}
  end

  @spec schedule_notifications([Notification.t]) :: :ok
  defp enqueue_notifications(notifications) do
    Enum.map(notifications, &HoldingQueue.enqueue/1)
  end

  @spec build_notifications(Subscription.t, Alert.t, DateTime.t | nil) :: [Notification.t]
  defp build_notifications(%Subscription{user: user}, %Alert{active_period: ap} = alert, now) do
    Enum.map(ap, fn(active_period) ->
      {:ok, start_time} = Calendar.DateTime.Parse.rfc3339_utc(active_period.start)

      {:ok, end_time} = case active_period.end do
        nil -> {:ok, nil}
        _ -> Calendar.DateTime.Parse.rfc3339_utc(active_period.end)
      end

     %Notification{
        alert_id: alert.id,
        user_id: user.id,
        header: alert.header,
        phone_number: user.phone_number,
        email: user.email,
        status: :unsent,
        send_after: calculate_send_after(user, {start_time, end_time}, now)
      }
    end)
  end

  # For a given user and active period, determines if/when the notification should
  # be scheduled to be sent based on user's vacation/blackout periods
  @spec calculate_send_after(User.t, {Time.t, Time.t | nil}, DateTime.t) :: Time.t | nil
  defp calculate_send_after(%User{
      vacation_start: vs,
      vacation_end: ve,
      do_not_disturb_start: dnd_start,
      do_not_disturb_end: dnd_end
  }, active_period, now) do

    send_after = {active_period, now}
    |> check_expired
    |> check_send_immediately
    |> check_vacation_period({vs, ve})
    |> check_do_not_disturb({dnd_start, dnd_end})

    case send_after do
      {:ok, time} -> time
      {:error} -> nil
    end
  end

  # @spec check_expired({Time.t, Time.t | nil}, Time.t) :: {:error} | {:ok, {Time.t, Time.t | nil}, Time.t}
  defp check_expired({{_start_time, nil} = active_period, now}), do: {:ok, active_period, now}
  defp check_expired({{_start_time, end_time} = active_period, now}) do
    case Calendar.DateTime.after?(now, end_time) do
      true -> {:error}
      false -> {:ok, active_period, now}
    end
  end

  @spec check_send_immediately({:ok, {Time.t, Time.t | nil}, Time.t}) :: {:error} | {:ok, {Time.t, Time.t | nil}, Time.t}
  defp check_send_immediately({:error}), do: {:error}
  defp check_send_immediately({:ok, {start_time, _} = active_period, now}) do
    sending_time = Calendar.DateTime.subtract!(start_time, @notification_time)
    case Calendar.DateTime.after?(now, sending_time) do
      true -> {:ok, active_period, now}
      false -> {:ok, active_period, sending_time}
    end
  end

  # Checks if a notification is wholly within vacation period. If so, does not send.
  # If not, checks if notification should go out at default time or needs to be adjusted
  # due to the vacation period overlapping the sending time
  @spec check_vacation_period({:ok, {Time.t, Time.t | nil}, {Time.t | nil, Time.t | nil}} | {:error}) :: {:error} | {:ok, {Time.t, Time.t | nil}, Time.t}
  defp check_vacation_period({:error}), do: {:error}
  defp check_vacation_period({:ok, {start_time, end_time}, sending_time}, {nil, nil}) do
    {:ok, {start_time, end_time}, sending_time}
  end
  defp check_vacation_period({:ok, {start_time, end_time}, sending_time}, {vacation_start, vacation_end}) do
    case in_vacation_period?(sending_time, end_time, vacation_start, vacation_end) do
      true -> {:error}
      false ->
        case Calendar.DateTime.after?(sending_time, vacation_end) do
          true -> {:ok, {start_time, end_time}, sending_time}
          false -> {:ok, {start_time, end_time}, vacation_end}
        end
    end
  end

  @spec in_vacation_period?(DateTime.t, DateTime.t | nil, DateTime.t | nil, DateTime.t | nil) :: boolean()
  defp in_vacation_period?(_sending_time, nil, _vacation_start, _vacation_end), do: false
  defp in_vacation_period?(sending_time, end_time, vacation_start, vacation_end) do
    !Calendar.DateTime.before?(sending_time, vacation_start) && !Calendar.DateTime.after?(end_time, vacation_end)
  end

  # Checks if a notification is wholly within blackout period. If so, does not send.
  # If not, checks if notification should go out at default time or needs to be adjusted
  # due to the blackout period overlapping the sending time

  # Since a blackout period is based on Time and not DateTime, intervals that are the
  # same day vs. overnight need to be handled separately. This determines which check
  # should be used for blackout period
  # Example 1: 10am - 8pm
  # Example 2: 8pm - 2am
  @spec check_do_not_disturb({:ok, {{DateTime.t, DateTime.t | nil}, DateTime.t}, {Time.t | nil, Time.t | nil}} | {:error} | {:error}, any()) :: {:error} | {:ok, DateTime.t}
  defp check_do_not_disturb({:error}), do: {:error}
  defp check_do_not_disturb({:error}, _), do: {:error}
  defp check_do_not_disturb({:ok, {_start_time, _end_time}, sending_time}, {nil, nil}) do
    {:ok, sending_time}
  end
  defp check_do_not_disturb({:ok, {_start_time, nil}, sending_time}, {dnd_start, dnd_end}) do
    params = {dnd_start, dnd_end, sending_time}
    case dnd_start < dnd_end do
      true -> check_same_day(params)
      false -> check_overnight(params)
    end
  end
  defp check_do_not_disturb({:ok, {_start_time, end_time}, sending_time}, {dnd_start, dnd_end}) do
    params = {dnd_start, dnd_end, sending_time, end_time}
    case dnd_start < dnd_end do
      true -> check_same_day(params)
      false -> check_overnight(params)
    end
  end

  # For blackout intervals that start/stop in the same day
  # 1. Checks if the notification sending_time and end_time
  # are completely within blackout
  # 2. If yes, do not send
  # 3. If no, determine whether blackout ends before send_at
  # 4. If yes, send_at stays the same
  # 5. If no, send_at is end of blackout
  @spec check_same_day({Time.t | nil, Time.t | nil, DateTime.t, Time.t | nil}) :: {:error} | {:ok, DateTime.t}
  defp check_same_day({dnd_start, dnd_end, sending_time, end_time}) do
    dnd_start_dt = time_to_datetime(dnd_start, sending_time)
    dnd_end_dt = time_to_datetime(dnd_end, sending_time)

    cond do
      !Calendar.DateTime.after?(dnd_start_dt, sending_time)
      && !Calendar.DateTime.after?(end_time, dnd_end_dt) ->
        {:error}
      !Calendar.DateTime.after?(dnd_start_dt, sending_time)
      && !Calendar.DateTime.after?(dnd_end_dt, end_time) ->
        {:ok, dnd_end_dt}
      true ->
        {:ok, sending_time}
    end
  end

  @spec check_same_day({Time.t | nil, Time.t | nil, DateTime.t}) :: {:ok, DateTime.t}
  defp check_same_day({dnd_start, dnd_end, sending_time}) do
    dnd_start_dt = time_to_datetime(dnd_start, sending_time)
    case !Calendar.DateTime.after?(dnd_start_dt, sending_time) do
      true -> {:ok, time_to_datetime(dnd_end, sending_time)}
      false -> {:ok, sending_time}
    end
  end

  # For blackout intervals that goes into the next day
  # 1. Checks if the notification sending_time and end_time
  # are completely within blackout
  # 2. If yes, do not send
  # 3. If no, determine whether blackout ends before send_at
  # 4. If yes, send_at stays the same
  # 5. If no, send_at is end of blackout
  @spec check_overnight({Time.t | nil, Time.t | nil, DateTime.t, Time.t | nil}) :: {:error} | {:ok, DateTime.t}
  defp check_overnight({dnd_start, dnd_end, sending_time, end_time}) do
    dnd_start_dt = time_to_datetime(dnd_start, sending_time)
    dnd_end_dt_day1 = time_to_datetime(dnd_end, sending_time)
    dnd_end_dt_day2 = time_to_datetime(dnd_end, Calendar.DateTime.add!(sending_time, 86_400))

    cond do
      !Calendar.DateTime.after?(sending_time, dnd_end_dt_day1)
      && !Calendar.DateTime.after?(end_time, dnd_end_dt_day1) ->
        {:error}
      !Calendar.DateTime.after?(sending_time, dnd_end_dt_day1)
        {:ok, dnd_end_dt_day1}
      !Calendar.DateTime.after?(dnd_start_dt, sending_time)
      && !Calendar.DateTime.after?(dnd_end_dt_day2, end_time) ->
        {:ok, dnd_end_dt_day2}
      true ->
        {:ok, sending_time}
    end
  end

  @spec check_overnight({Time.t | nil, Time.t | nil, DateTime.t}) :: {:ok, DateTime.t}
  defp check_overnight({dnd_start, dnd_end, sending_time}) do
    dnd_start_dt = time_to_datetime(dnd_start, sending_time)
    dnd_end_next_day = time_to_datetime(dnd_end, Calendar.DateTime.add!(sending_time, 86_400))
    case !Calendar.DateTime.after?(dnd_start_dt, sending_time) do
      true -> {:ok, dnd_end_next_day}
      false -> {:ok, sending_time}
    end
  end

  @spec time_to_datetime(Time.t | nil, DateTime.t) :: DateTime.t | nil
  defp time_to_datetime(time, datetime) do
    erl_time = Calendar.Time.to_erl(time)
    erl_date = Calendar.DateTime.to_date(datetime)
    Calendar.DateTime.from_date_and_time_and_zone!(erl_date, erl_time, "Etc/UTC")
  end
end
