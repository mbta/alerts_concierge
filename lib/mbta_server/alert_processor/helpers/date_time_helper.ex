defmodule MbtaServer.AlertProcessor.Helpers.DateTimeHelper do
  @moduledoc """
  Module containing reusable datetime helpers for
  mutlti-step datetime functions.
  """

  @type erl_time :: :calendar.time
  @type seconds :: integer

  @spec gregorian_day_range(NaiveDateTime.t, NaiveDateTime.t) :: Range.t
  def gregorian_day_range(start_datetime, end_datetime) do
    {start_date_erl, _} = NaiveDateTime.to_erl(start_datetime)
    {end_date_erl, _} = NaiveDateTime.to_erl(end_datetime)

    :calendar.date_to_gregorian_days(start_date_erl)..:calendar.date_to_gregorian_days(end_date_erl)
  end

  @spec seconds_of_day(erl_time) :: seconds
  def seconds_of_day({hour, minute, second}) do
    (hour * 3600) + (minute * 60) + second
  end
end
