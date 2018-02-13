defmodule AlertProcessor.ActivePeriodFilter do
  @moduledoc """
  Filter subscriptions based on matching an active period in an alert
  """
  alias AlertProcessor.Model.Subscription

  @doc """
  filter/1 takes a tuple including a subquery which represents the remaining
  subscriptions to be considered and an alert and returns the now remaining
  subscriptions to be considered in the form of an ecto queryable which have
  been matched based on the active period(s) in the alert.
  """
  @spec filter([Subscription.t], Keyword.t) :: [Subscription.t]
  def filter(subscriptions, [alert: alert]) do
    do_filter(subscriptions, alert)
  end

  defp do_filter(subscriptions, %{active_period: active_period}) do
    now = DateTime.utc_now()
    Enum.filter(subscriptions, &check_active_period(now, active_period, &1))
  end

  def check_active_period(now, periods, %{start_time: start_time, end_time: end_time, relevant_days: relevant_days}) do
    # don't match an alert that is too far in the future
    if check_too_distant_exclusion(List.first(periods), now) do
      false
    else
      period_dates = periods_to_dates(periods)
      alert_days_of_week = alert_days_of_week(period_dates)
      subscription_days_of_week = subscription_days_of_week(relevant_days, start_time > end_time)

      # exclude period based on relevant days
      if check_day_of_week_exclusion(alert_days_of_week, subscription_days_of_week) do
        false
      else
        # make subscription times relative to period
        subscription_periods = translate_subscription_days(period_dates, subscription_days_of_week, start_time, end_time)

        # check if any period overlaps
        Enum.any?(periods, &check_overlapping_periods(&1, subscription_periods))
      end
    end
  end

  defp check_overlapping_periods(period, subscription_periods) do
    Enum.any?(subscription_periods, &date_intersects?(period.start, period.end, &1.start, &1.end))
  end

  defp date_intersects?(alert_start, _alert_end, sub_start, _sub_end) when alert_start == sub_start, do: true
  defp date_intersects?(alert_start, alert_end, sub_start, sub_end) do
    if alert_start > sub_start, do: alert_start <= sub_end, else: sub_start <= alert_end
  end

  defp check_too_distant_exclusion(%{start: start_date}, now) do
    gregorian_first_day = :calendar.date_to_gregorian_days({now.year, now.month, now.day})
    gregorian_last_day = :calendar.date_to_gregorian_days({start_date.year, start_date.month, start_date.day})
    gregorian_last_day - gregorian_first_day > 2
  end

  defp check_day_of_week_exclusion(alert_days_of_week, subscription_days_of_week) do
    MapSet.intersection(alert_days_of_week, subscription_days_of_week) == MapSet.new
  end

  defp translate_subscription_days(period_dates, subscription_days_of_week, start_time, end_time) do
    period_dates
    |> Enum.filter(&MapSet.member?(subscription_days_of_week, Date.day_of_week(&1)))
    |> Enum.map(& do_translate_subscription_day(&1, start_time, end_time))
    |> adjust_for_overnight(subscription_days_of_week, start_time > end_time)
    |> List.flatten
  end

  defp do_translate_subscription_day(date, start_time, end_time) when start_time < end_time do
    [%{start: make_datetime(date.year, date.month, date.day, start_time.hour, start_time.minute, 0),
         end: make_datetime(date.year, date.month, date.day, end_time.hour, end_time.minute, 0)}]
  end
  defp do_translate_subscription_day(date, start_time, end_time) when start_time > end_time do
    [%{start: make_datetime(date.year, date.month, date.day, start_time.hour, start_time.minute, 0),
         end: make_datetime(date.year, date.month, date.day, 23, 59, 59)},
     %{start: make_datetime(date.year, date.month, date.day, 0, 0, 0),
         end: make_datetime(date.year, date.month, date.day, end_time.hour, end_time.minute, 0)}]
  end

  defp make_datetime(year, month, day, hour, minute, second) do
    %DateTime{year: year, month: month, day: day, hour: hour, minute: minute, zone_abbr: "EST", second: second,
              microsecond: {0, 0}, utc_offset: -5, std_offset: 0, time_zone: "America/New_York"}
  end

  defp adjust_for_overnight(dates, subscription_days_of_week, true) do
    first_day = Enum.take(subscription_days_of_week, 1)
    last_day = Enum.take(subscription_days_of_week, -1)
    Enum.map(dates, &do_adjust_for_overnight(&1, Date.day_of_week(List.first(&1).start), first_day, last_day))
  end
  defp adjust_for_overnight(dates, _subscription_days_of_week, false), do: dates

  defp do_adjust_for_overnight(date, day_of_week, first_day, _last_day) when day_of_week == first_day do
    Enum.drop(date, 1)
  end
  defp do_adjust_for_overnight(date, day_of_week, _first_day, last_day) when day_of_week == last_day do
    Enum.drop(date, -1)
  end
  defp do_adjust_for_overnight(date, _day_of_week, _first_day, _last_day), do: date

  defp subscription_days_of_week(relevant_days, overnight?) do
    relevant_days
    |> Enum.flat_map(&translate_days(&1, overnight?))
    |> MapSet.new
  end

  defp translate_days(:saturday, false), do: [6]
  defp translate_days(:sunday, false), do: [7]
  defp translate_days(:weekday, false), do: [1, 2, 3, 4, 5]
  defp translate_days(:saturday, true), do: [6, 7]
  defp translate_days(:sunday, true), do: [7, 1]
  defp translate_days(:weekday, true), do: [1, 2, 3, 4, 5, 6]

  defp periods_to_dates(periods), do: Enum.flat_map(periods, &do_periods_to_dates(&1))

  defp do_periods_to_dates(%{start: start_date, end: end_date}) when start_date <= end_date do
    gregorian_start_day = :calendar.date_to_gregorian_days({start_date.year, start_date.month, start_date.day})
    gregorian_end_day = :calendar.date_to_gregorian_days({end_date.year, end_date.month, end_date.day})
    gregorian_start_day..gregorian_end_day
    |> Enum.map(fn(gregorian_day) ->
      gregorian_day
      |> :calendar.gregorian_days_to_date()
      |> Date.from_erl!()
    end)
  end

  defp alert_days_of_week(dates) do
    dates
    |> Enum.map(&Date.day_of_week(&1))
    |> MapSet.new
  end
end
