defmodule ConciergeSite.TimeHelper do
  @moduledoc """
  Time functions for subscription views
  """

  alias Calendar.Strftime

  @doc """
  Takes a time struct and returns HH:MM AM/PM
  """
  def format_time(time, format \\ "%l:%M %p")
  def format_time(nil, _), do: ""

  def format_time(time, format) do
    time
    |> time_to_string()
    |> format_time_string(format)
  end

  @doc """
  Takes a time string in format HH:MM:SS and returns HH:MM AM/PM
  """
  def format_time_string(time_string, format \\ "%l:%M %p") do
    time_string
    |> String.split(":")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
    |> Time.from_erl!()
    |> Strftime.strftime!(format)
  end

  @doc """
  Converts a Time.t to a string with the H:M:S format
  """
  @spec time_to_string(Time.t() | nil) :: String.t() | nil
  def time_to_string(nil), do: nil
  def time_to_string(time), do: Strftime.strftime!(time, "%H:%M:%S")
end
