defmodule AlertProcessor.DateHelper do
  @moduledoc """
  Useful date transformations for tests.
  """
  @time_zone "America/New_York"

  @spec naive_to_local(NaiveDateTime.t()) :: DateTime.t()
  def naive_to_local(naive_datetime) do
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> Calendar.DateTime.shift_zone!(@time_zone)
  end
end
