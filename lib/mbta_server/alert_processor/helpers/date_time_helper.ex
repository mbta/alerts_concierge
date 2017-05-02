defmodule MbtaServer.AlertProcessor.Helpers.DateTimeHelper do
  @moduledoc """
  Module containing reusable datetime helpers for
  multi-step datetime functions.
  """

  @spec datetime_to_date_and_time(NaiveDateTime.t) :: {Date.t, Time.t}
  def datetime_to_date_and_time(datetime) do
    date = NaiveDateTime.to_date(datetime)
    time = NaiveDateTime.to_time(datetime)

    {date, time}
  end

  @spec gregorian_day_range(NaiveDateTime.t, NaiveDateTime.t) :: Range.t
  def gregorian_day_range(start_datetime, end_datetime) do
    {start_date_erl, _} = NaiveDateTime.to_erl(start_datetime)
    {end_date_erl, _} = NaiveDateTime.to_erl(end_datetime)

    :calendar.date_to_gregorian_days(start_date_erl)..:calendar.date_to_gregorian_days(end_date_erl)
  end

  @spec gregorian_day_to_date(integer) :: {:ok, Date.t} | {:error, atom}
  def gregorian_day_to_date(gregorian_day) do
    gregorian_day
    |> :calendar.gregorian_days_to_date
    |> Date.from_erl
  end

  @spec seconds_of_day(Time.t) :: MbtaServer.AlertProcessor.TimeFrameComparison.second_of_day
  def seconds_of_day(timestamp) do
    {hour, minute, second} = Time.to_erl(timestamp)
    (hour * 3600) + (minute * 60) + second
  end
end
