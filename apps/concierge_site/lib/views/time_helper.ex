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
  def format_time_string(time_string, format \\ "%l:%M %p") do
    time_string
    |> String.split(":")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
    |> Time.from_erl!
    |> Strftime.strftime!(format)
  end

  @doc """
  Takes Time.t and returns HH:MMam/pm
  """
  @spec format_time(Time.t) :: String.t
  def format_time(time) do
    {:ok, output} = Strftime.strftime(time, "%l:%M%P")
    output
  end

  @doc """
  Converts a Time.t to a string with the H:M:S format
  """
  @spec time_to_string(Time.t | nil) :: String.t | nil
  def time_to_string(nil), do: nil
  def time_to_string(time), do: Strftime.strftime!(time, "%H:%M:%S")
end
