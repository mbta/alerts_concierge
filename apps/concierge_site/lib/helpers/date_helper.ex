defmodule ConciergeSite.Helpers.DateHelper do
  @moduledoc """
  Functions to use for formatting dates throughout the application
  """

  alias Calendar.Strftime

  @time_zone "America/New_York"

  def format_datetime(datetime), do: Strftime.strftime!(datetime, "%b %d %Y %I:%M %p")
  def format_datetime(datetime, :local) do
    datetime
    |> Calendar.DateTime.shift_zone!(@time_zone)
    |> format_datetime()
  end
end
