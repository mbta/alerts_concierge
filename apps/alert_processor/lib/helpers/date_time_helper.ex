defmodule AlertProcessor.Helpers.DateTimeHelper do
  @moduledoc """
  Module containing reusable datetime helpers for
  multi-step datetime functions.
  """
  @seconds_in_a_day 86_400

  alias Calendar.Date, as: D
  alias Calendar.DateTime, as: DT
  alias Calendar.Time, as: T
  alias Calendar.Date, as: D
  alias Calendar.Strftime

  @spec time_without_zone(String.t) :: Time.t
  def time_without_zone(date), do: date |> NaiveDateTime.from_iso8601! |> NaiveDateTime.to_time

  @spec datetime_to_date_and_time(DateTime.t) :: {Date.t, Time.t}
  def datetime_to_date_and_time(datetime) do
    date = DateTime.to_date(datetime)
    time = DateTime.to_time(datetime)

    {date, time}
  end

  @spec date_range(DateTime.t, DateTime.t) :: [Date.t]
  def date_range(%DateTime{} = start_datetime, %DateTime{} = end_datetime) do
    {start_date_erl, _} = DT.to_erl(start_datetime)
    {end_date_erl, _} = DT.to_erl(end_datetime)
    do_date_range(start_date_erl, end_date_erl)
  end

  @spec do_date_range(:calendar.date, :calendar.date) :: [Date.t]
  defp do_date_range(start_date_erl, end_date_erl) do
    range = :calendar.date_to_gregorian_days(start_date_erl)..:calendar.date_to_gregorian_days(end_date_erl)

    Enum.map(range, fn(x) ->
      {:ok, date} = gregorian_day_to_date(x)
      date
    end)
  end

  @spec gregorian_day_to_date(integer) :: {:ok, Date.t} | {:error, atom}
  defp gregorian_day_to_date(gregorian_day) do
    gregorian_day
    |> :calendar.gregorian_days_to_date
    |> Date.from_erl
  end

  @spec seconds_of_day(Time.t) :: AlertProcessor.TimeFrameComparison.second_of_day
  def seconds_of_day(timestamp) do
    {hour, minute, second} = Time.to_erl(timestamp)
    (hour * 3600) + (minute * 60) + second
  end

  @spec format_date(NaiveDateTime.t, String.t) :: any
  def format_date(datetime, timezone \\ "America/New_York") do
    with {:ok, utc_datetime} <- DateTime.from_naive(datetime, "Etc/UTC"),
         {:ok, local_datetime} <- DT.shift_zone(utc_datetime, timezone),
         {:ok, output} <- Strftime.strftime(local_datetime, "%m-%d-%Y") do
      output
    end
  end

  @doc """
  Takes 4 arguments:
  1. The interval length in seconds (1 week)
  2. The day of the week the digest goes out
  3. The time of day the digest goes out
  4. {current_date, current_time}

  It then calculates the number of seconds to the next Date/Time the digest would go out.
  Accounts for negative days (current day of week is > day of week digest goes out)
  Accounts for negative time (current time is > time of day digest goes out)
  """
  @spec seconds_until_next_digest(integer, integer, Time.t, {Date.t, Time.t}) :: integer
  def seconds_until_next_digest(interval, day_of_week, time_of_day, {date, time}) do
    difference = difference_in_days_as_seconds(day_of_week, date) +
                 difference_in_time_as_seconds(time_of_day, time)
    if difference >= 0 do
      difference
    else
      interval + difference
    end
  end

  defp difference_in_days_as_seconds(day_of_week, today) do
    current_day_of_week = today |> Date.day_of_week
    (day_of_week - current_day_of_week) * @seconds_in_a_day
  end

  defp difference_in_time_as_seconds(time_of_day, time_now) do
    T.diff(time_of_day, time_now)
  end

  @doc """
  Returns a tuple of the datetime of the upcoming weekend.
  If called on a weekend, will go back to start of current weekend.
  """
  @spec upcoming_weekend(DateTime.t | nil) :: {DateTime.t, DateTime.t}
  def upcoming_weekend(time \\ nil) do
    today = time || DT.now!("America/New_York")

    start_time = today
    |> Map.merge(%{
      hour: 2,
      minute: 30,
      second: 1,
      microsecond: {0, 0}
    })
    |> DT.add!(seconds_till_saturday(today))
    end_time = DT.add!(start_time, @seconds_in_a_day * 2 - 1)

    {start_time, end_time}
  end

  @spec seconds_till_saturday(DateTime.t) :: number
  defp seconds_till_saturday(date_time) do
    day_of_week = date_time
    |> DT.to_date
    |> D.day_of_week
    if day_of_week >= 6 do
      (6 - day_of_week) * @seconds_in_a_day + 7 * @seconds_in_a_day
    else
      (6 - day_of_week) * @seconds_in_a_day
    end
  end

  @doc """
  Returns a tuple of DateTimes of the upcoming week
  """
  @spec upcoming_week(DateTime.t | nil) :: {DateTime.t, DateTime.t}
  def upcoming_week(time \\ nil) do
    {_start, end_of_weekend} = upcoming_weekend(time)
    start_time = DT.add!(end_of_weekend, 1)
    end_time = DT.add!(start_time, @seconds_in_a_day * 5 - 1)

    {start_time, end_time}
  end

  @doc """
  Returns a tuple of DateTimes of the next weekend (after upcoming week)
  """
  @spec next_weekend(DateTime.t | nil) :: {DateTime.t, DateTime.t}
  def next_weekend(time \\ nil) do
    {_start, end_of_week} = upcoming_week(time)
    start_time = DT.add!(end_of_week, 1)
    end_time = DT.add!(start_time, @seconds_in_a_day * 2 - 1)

    {start_time, end_time}
  end

  @spec future(DateTime.t | nil) :: {DateTime.t, DateTime.t}
  def future(time \\ nil) do
    {_start, end_of_next_weekend} = next_weekend(time)
    start_time = DT.add!(end_of_next_weekend, 1)
    end_time = DT.from_erl!({{3000, 01, 01}, {0, 0, 0}}, "America/New_York")
    {start_time, end_time}
  end

  @doc "Returns full name of month for a DateTime"
  @spec month_name(DateTime.t) :: String.t
  def month_name(date) do
    Strftime.strftime!(date, "%B")
  end

  @doc """
  Function to determine next date of relevant day type
  """
  def determine_date("weekday", today_date), do: determine_date(:weekday, today_date)
  def determine_date("saturday", today_date), do: determine_date(:saturday, today_date)
  def determine_date("sunday", today_date), do: determine_date(:sunday, today_date)
  def determine_date(:weekday, today_date) do
    if Calendar.Date.day_of_week(today_date) < 6 do
      today_date
    else
      Calendar.Date.advance!(today_date, 2)
    end
  end
  def determine_date(:saturday, today_date) do
    day_of_week = Calendar.Date.day_of_week(today_date)
    Calendar.Date.advance!(today_date, 6 - day_of_week)
  end
  def determine_date(:sunday, today_date) do
    day_of_week = Calendar.Date.day_of_week(today_date)
    Calendar.Date.advance!(today_date, 7 - day_of_week)
  end

  def determine_relevant_day_of_week(datetime, local_datetime \\ "America/New_York") do
    {:ok, adjusted_datetime} = DT.shift_zone(datetime, local_datetime)
    day_of_week = Date.day_of_week(adjusted_datetime)
    time = DateTime.to_time(adjusted_datetime)
    do_determine_relevant_day_of_week(time, day_of_week)
  end

  defp do_determine_relevant_day_of_week(time, 7) do
    if in_current_service_date?(time) do
      :sunday
    else
      :saturday
    end
  end
  defp do_determine_relevant_day_of_week(time, 6) do
    if in_current_service_date?(time)do
      :saturday
    else
      :weekday
    end
  end
  defp do_determine_relevant_day_of_week(time, 1) do
    if in_current_service_date?(time) do
      :weekday
    else
      :sunday
    end
  end
  defp do_determine_relevant_day_of_week(_, _) do
    :weekday
  end

  defp in_current_service_date?(time) do
    Time.compare(time, ~T[03:00:00]) == :gt
  end
end
