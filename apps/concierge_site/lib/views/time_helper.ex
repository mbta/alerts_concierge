defmodule ConciergeSite.TimeHelper do
  @moduledoc """
  Time functions for subscription views
  """

  alias Calendar.Time, as: T
  alias Calendar.Strftime
  alias AlertProcessor.Helpers.DateTimeHelper

  @doc """
  Returns stringified times to populate a dropdown list of a full day of times at
  fifteen-minute intervals
  """
  def travel_time_options do
   10_800
    |> Stream.iterate(&(&1 + 900))
    |> Stream.map(&(rem(&1, 86_400)))
    |> Stream.map(&T.from_second_in_day/1)
    |> Stream.map((& {Strftime.strftime!(&1, "%I:%M %p"), Strftime.strftime!(&1, "%H:%M:%S")}))
    |> Enum.take(96)
  end

  @doc """
  Takes a time string in format HH:MM:SS and returns HH:MM AM/PM
  """
  def format_time(time) do
    time
    |> String.split(":")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
    |> Time.from_erl!
    |> Strftime.strftime!("%l:%M %p")
    |> String.replace_leading(" ", "")
  end

  @doc """
  Converts a utc timestamp to local time stringifiied in the H:M:S format
  """
  @spec time_option_local_strftime(Time.t | nil) :: String.t | nil
  def time_option_local_strftime(nil), do: nil
  def time_option_local_strftime(timestamp) do
    timestamp
    |> DateTimeHelper.utc_time_to_local()
    |> Strftime.strftime!("%H:%M:%S")
  end

  @doc """
  Converts timestamp into integer value adjusting late night, after
  midnight values into higher than times before midnight.
  """
  @spec normalized_time_value(Time.t) :: integer
  def normalized_time_value(timestamp) do
    stv = DateTimeHelper.seconds_of_day(timestamp)
    if stv < 10_800 do
      stv + 86_400
    else
      stv
    end
  end
end
