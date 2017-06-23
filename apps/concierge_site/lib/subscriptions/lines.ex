defmodule ConciergeSite.Subscriptions.Lines do
  @moduledoc """
  Module for transforming ServiceInfoCache info
  """

  alias AlertProcessor.ServiceInfoCache

  @doc """
  Transform AlertProcessor.Model.Route struct into keyword list of {"Line Name", [Stations]}

  For use in the Phoenix.HTML.Form.select helper, so that the line name can
  become the label of an <optgroup> containing <option>s for each station.
  """

  @spec station_list_select_options([%AlertProcessor.Model.Route{}]) :: [{String.t, list}]
  def station_list_select_options(routes) do
    Enum.map(routes, fn(route) -> {route.long_name, route.stop_list} end)
  end

  @doc """
  Fetch the station name for a given stop id
  """
  @spec subway_station_name_from_id(String.t) :: String.t
  def subway_station_name_from_id(id) do
    case ServiceInfoCache.get_subway_full_routes() do
      {:ok, stations} ->
        stations
        |> Enum.flat_map(fn station -> station.stop_list end)
        |> Enum.find(id, fn {_name, station_id} -> id == station_id end)
        |> elem(0)
      _error ->
        id
    end
  end
end
