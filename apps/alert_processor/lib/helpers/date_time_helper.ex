defmodule AlertProcessor.Helpers.DateTimeHelper do
  @moduledoc """
  Module containing reusable datetime helpers for
  multi-step datetime functions.
  """
  @time_zone "America/New_York"

  alias Calendar.DateTime, as: DT
  alias Calendar.Strftime

  @spec time_without_zone(String.t()) :: Time.t()
  def time_without_zone(date),
    do: date |> NaiveDateTime.from_iso8601!() |> NaiveDateTime.to_time()

  @spec datetime_to_date_and_time(DateTime.t()) :: {Date.t(), Time.t()}
  def datetime_to_date_and_time(datetime) do
    date = DateTime.to_date(datetime)
    time = DateTime.to_time(datetime)

    {date, time}
  end

  @spec date_range(DateTime.t(), DateTime.t()) :: [Date.t()]
  def date_range(%DateTime{} = start_datetime, %DateTime{} = end_datetime) do
    {start_date_erl, _} = DT.to_erl(start_datetime)
    {end_date_erl, _} = DT.to_erl(end_datetime)
    do_date_range(start_date_erl, end_date_erl)
  end

  @spec do_date_range(:calendar.date(), :calendar.date()) :: [Date.t()]
  defp do_date_range(start_date_erl, end_date_erl) do
    range =
      :calendar.date_to_gregorian_days(start_date_erl)..:calendar.date_to_gregorian_days(
        end_date_erl
      )

    Enum.map(range, fn x ->
      {:ok, date} = gregorian_day_to_date(x)
      date
    end)
  end

  @spec gregorian_day_to_date(integer) :: {:ok, Date.t()} | {:error, atom}
  defp gregorian_day_to_date(gregorian_day) do
    gregorian_day
    |> :calendar.gregorian_days_to_date()
    |> Date.from_erl()
  end

  @spec seconds_of_day(Time.t()) :: AlertProcessor.TimeFrameComparison.second_of_day()
  def seconds_of_day(timestamp) do
    {hour, minute, second} = Time.to_erl(timestamp)
    hour * 3600 + minute * 60 + second
  end

  @spec format_date(NaiveDateTime.t(), String.t()) :: String.t()
  def format_date(datetime, time_zone \\ @time_zone) do
    with {:ok, utc_datetime} <- DateTime.from_naive(datetime, "Etc/UTC"),
         {:ok, local_datetime} <- DT.shift_zone(utc_datetime, time_zone),
         {:ok, output} <- Strftime.strftime(local_datetime, "%m-%d-%Y") do
      output
    end
  end

  @spec format_time(NaiveDateTime.t(), String.t()) :: String.t()
  def format_time(datetime, time_zone \\ @time_zone) do
    with {:ok, utc_datetime} <- DateTime.from_naive(datetime, "Etc/UTC"),
         {:ok, local_datetime} <- DT.shift_zone(utc_datetime, time_zone),
         {:ok, output} <- Strftime.strftime(local_datetime, "%l:%M%P") do
      output
    end
  end

  @spec datetime_to_local(DateTime.t(), String.t()) :: DateTime.t()
  def datetime_to_local(datetime, time_zone \\ @time_zone) do
    {:ok, local_datetime} =
      datetime
      |> DateTime.to_unix()
      |> FastLocalDatetime.unix_to_datetime(time_zone)

    local_datetime
  end

  @spec time_to_local_datetime(Time.t(), DateTime.t(), String.t()) :: DateTime.t()
  def time_to_local_datetime(time, utc_date, time_zone \\ @time_zone) do
    utc_date
    |> datetime_to_local(time_zone)
    |> Map.put(:hour, time.hour)
    |> Map.put(:minute, time.minute)
    |> Map.put(:second, time.second)
  end

  @doc "Returns full name of month for a DateTime"
  @spec month_name(DateTime.t()) :: String.t()
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

  def within_relevant_day_of_week?(relevant_days, datetime) do
    Enum.any?(determine_relevant_days_of_week(datetime), fn day ->
      Enum.member?(relevant_days, day)
    end)
  end

  defp determine_relevant_days_of_week(datetime, time_zone \\ @time_zone) do
    {:ok, adjusted_datetime} = DT.shift_zone(datetime, time_zone)
    day_of_week = Date.day_of_week(adjusted_datetime)
    time = DateTime.to_time(adjusted_datetime)
    do_determine_relevant_days_of_week(time, day_of_week)
  end

  defp do_determine_relevant_days_of_week(time, 1) do
    if in_current_service_date?(time) do
      [:weekday, :monday]
    else
      [:sunday]
    end
  end

  defp do_determine_relevant_days_of_week(time, 2) do
    if in_current_service_date?(time) do
      [:weekday, :tuesday]
    else
      [:weekday, :monday]
    end
  end

  defp do_determine_relevant_days_of_week(time, 3) do
    if in_current_service_date?(time) do
      [:weekday, :wednesday]
    else
      [:weekday, :tuesday]
    end
  end

  defp do_determine_relevant_days_of_week(time, 4) do
    if in_current_service_date?(time) do
      [:weekday, :thursday]
    else
      [:weekday, :wednesday]
    end
  end

  defp do_determine_relevant_days_of_week(time, 5) do
    if in_current_service_date?(time) do
      [:weekday, :friday]
    else
      [:weekday, :thursday]
    end
  end

  defp do_determine_relevant_days_of_week(time, 6) do
    if in_current_service_date?(time) do
      [:saturday]
    else
      [:weekday, :friday]
    end
  end

  defp do_determine_relevant_days_of_week(time, 7) do
    if in_current_service_date?(time) do
      [:sunday]
    else
      [:saturday]
    end
  end

  defp in_current_service_date?(time) do
    Time.compare(time, ~T[03:00:00]) == :gt
  end

  @spec parse_unix_timestamp(integer, String.t()) :: {:ok, DateTime.t()} | :error
  def parse_unix_timestamp(timestamp, time_zone \\ @time_zone) do
    case FastLocalDatetime.unix_to_datetime(timestamp, time_zone) do
      {:ok, datetime} -> {:ok, datetime}
      _ -> :error
    end
  end
end
