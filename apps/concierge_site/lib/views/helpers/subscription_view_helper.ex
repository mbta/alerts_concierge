defmodule ConciergeSite.SubscriptionViewHelper do
  @moduledoc """
  Functions used across subscription views
  """
  alias Calendar.{Time, Strftime}

  @doc """
  Returns stringified times to populate a dropdown list of a full day of times at
  fifteen-minute intervals
  """
  def travel_time_options do
    0
    |> Stream.iterate(&(&1 + 900))
    |> Stream.map(&Time.from_second_in_day/1)
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
    |> Strftime.strftime!("%I:%M %p")
  end
end
