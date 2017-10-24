defmodule ConciergeSite.Helpers.MultiSelectHelper do
  alias ConciergeSite.Subscriptions.Lines

  def station_options(cr_stations, subway_stations) do
    subway_stations
    |> Kernel.++(cr_stations)
    |> Lines.station_list_select_options()
  end
end
