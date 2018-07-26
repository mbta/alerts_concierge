defmodule ConciergeSite.ParamParsers.ParamTime do
  @moduledoc """
  Helpers for parsing time input
  """

  @doc ~S"""
  Translate an input param string to a Time

  ## Examples

      iex> ConciergeSite.ParamParsers.ParamTime.to_time(%{"am_pm" => "AM", "hour" => "01", "minute" => "30"})
      ~T[01:30:00]
      iex> ConciergeSite.ParamParsers.ParamTime.to_time(%{"am_pm" => "PM", "hour" => "02", "minute" => "00"})
      ~T[14:00:00]
      iex> ConciergeSite.ParamParsers.ParamTime.to_time(%{"am_pm" => "AM", "hour" => "00", "minute" => "00"})
      ~T[00:00:00]
      iex> ConciergeSite.ParamParsers.ParamTime.to_time(%{"am_pm" => "AM", "hour" => "12", "minute" => "00"})
      ~T[00:00:00]
      iex> ConciergeSite.ParamParsers.ParamTime.to_time(%{"am_pm" => "PM", "hour" => "12", "minute" => "00"})
      ~T[12:00:00]
      iex> ConciergeSite.ParamParsers.ParamTime.to_time(nil)
      nil
  """
  @spec to_time(map) :: Time.t()
  def to_time(nil), do: nil

  def to_time(form_time) do
    hour = hour(form_time["hour"], form_time["am_pm"])
    minute = String.to_integer(form_time["minute"])
    second = 0

    {:ok, time} = Time.from_erl({hour, minute, second})

    time
  end

  @spec hour(number | String.t(), String.t()) :: number
  defp hour(hour_string, am_pm) when is_bitstring(hour_string),
    do: hour(String.to_integer(hour_string), am_pm)

  defp hour(hour, am_pm) do
    cond do
      am_pm == "PM" and hour != 12 ->
        hour + 12

      am_pm == "AM" and hour == 12 ->
        0

      true ->
        hour
    end
  end
end
