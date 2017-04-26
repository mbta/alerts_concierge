defmodule MbtaServer.AlertProcessor.Helpers.DateTimeHelper do
  @moduledoc """
  Module containing reusable datetime helpers for
  mutlti-step datetime functions.
  """

  @type erl_date :: {integer, integer, integer}
  @type erl_time :: {integer, integer, integer}
  @type seconds :: integer

  @spec datetime_to_date_and_time(DateTime.t) :: {Date.t, Time.t}
  def datetime_to_date_and_time(datetime) do
    date = DateTime.to_date(datetime)
    time = DateTime.to_time(datetime)

    {date, time}
  end

  @spec datetime_to_erl(DateTime.t) :: {erl_date, erl_time}
  def datetime_to_erl(datetime) do
    {date, time} = datetime_to_date_and_time(datetime)

    {Date.to_erl(date), Time.to_erl(time)}
  end

  @spec gregorian_day_range(DateTime.t, DateTime.t) :: Range.t
  def gregorian_day_range(start_datetime, end_datetime) do
    {start_date_erl, _} = datetime_to_erl(start_datetime)
    {end_date_erl, _} = datetime_to_erl(end_datetime)

    :calendar.date_to_gregorian_days(start_date_erl)..:calendar.date_to_gregorian_days(end_date_erl)
  end

  @spec seconds_of_day(erl_time) :: seconds
  def seconds_of_day({hour, minute, second}) do
    (hour * 3600) + (minute * 60) + second
  end
end
