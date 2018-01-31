defmodule ConciergeSite.Helpers.DateHelper do
  @moduledoc """
  Functions to use for formatting dates throughout the application
  """

  alias Calendar.Strftime

  def format_datetime(date), do: Strftime.strftime!(date, "%b %d %Y %I:%M %p")
end
