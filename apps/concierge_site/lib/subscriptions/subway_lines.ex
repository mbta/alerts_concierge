defmodule ConciergeSite.Subscriptions.SubwayLines do
  @moduledoc """
  Module for transforming ServiceInfoCache subway info
  """

  @typedoc """
  Map of Subway lines and lists of associated stations
  """
  @type subway_service_info :: %{{String.t, integer} => [{String.t, String.t}]}

  @doc """
  Transform station map into keyword list of {"Line Name", [Stations]}

  For use in the Phoenix.HTML.Form.select helper, so that the line name can
  become the label of an <optgroup> containing <option>s for each station.
  """

  @spec station_list_select_options(subway_service_info) :: [{String.t, list}]
  def station_list_select_options(stations) do
    Enum.map(stations, fn({line, station_list}) ->
      {elem(line, 0), station_list}
    end)
  end
end
