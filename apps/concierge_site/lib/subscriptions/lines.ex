defmodule ConciergeSite.Subscriptions.Lines do
  @moduledoc """
  Module for transforming ServiceInfoCache info
  """

  alias AlertProcessor.{ServiceInfoCache, Model.Route}

  @doc """
  Transform AlertProcessor.Model.Route struct into keyword list of {"Line Name", [Stations]}

  For use in the Phoenix.HTML.Form.select helper, so that the line name can
  become the label of an <optgroup> containing <option>s for each station.
  """
  @spec station_list_select_options([%Route{}]) :: [{String.t, list}]
  def station_list_select_options(routes) do
    Enum.map(routes, fn(route) -> {Route.name(route, :long_name), route.stop_list} end)
  end

  @doc """
  Fetch the associated station names for a given origin and destination station ids
  """
  @spec subway_station_names_from_ids(map) :: map
  def subway_station_names_from_ids(selected_station_ids) do
    case ServiceInfoCache.get_subway_full_routes() do
      {:ok, stations} ->
        station_list = Enum.flat_map(stations, fn station -> station.stop_list end)

        for {key, station_id} <- selected_station_ids do
          {name, _id} = Enum.find(
            station_list,
            {station_id, station_id},
            fn {_name, station_list_id} -> station_id == station_list_id end
          )
          {key, name}
        end
        |> Enum.into(%{})

      _error ->
        selected_station_ids
    end
  end
end
