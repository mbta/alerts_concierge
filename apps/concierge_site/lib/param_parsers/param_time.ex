defmodule ConciergeSite.ParamParsers.ParamTime do
  @moduledoc """
  Helpers for parsing time input
  """

  @doc ~S"""
  Translate an input param string to a Time

  ## Examples

      iex> ConciergeSite.ParamParsers.ParamTime.to_time("1:30 AM")
      ~T[01:30:00]
      iex> ConciergeSite.ParamParsers.ParamTime.to_time("2:00 PM")
      ~T[14:00:00]
      iex> ConciergeSite.ParamParsers.ParamTime.to_time(nil)
      nil
  """
  @spec to_time(String.t()) :: Time.t()
  def to_time(nil), do: nil

  def to_time(form_time) do
    {time_input, add_hours} = time_meridian(form_time)
    [hour, minute] = Enum.map(String.split(time_input, ":"), &String.to_integer/1)
    {:ok, time} = Time.new(hour + add_hours, minute, 0)

    time
  end

  defp time_meridian(form_time) do
    [time, meridian] = String.split(form_time, " ")
    [hour, _] = String.split(time, ":")
    pm_add_hours = if meridian == "PM" && hour != "12", do: 12, else: 0
    am_subtract_hours = if meridian == "AM" && hour == "12", do: 12, else: 0
    {time, pm_add_hours - am_subtract_hours}
  end
end
