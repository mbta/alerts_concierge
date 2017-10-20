defmodule ConciergeSite.Helpers.MultiSelectHelper do
  alias AlertProcessor.ServiceInfoCache
  alias ConciergeSite.Subscriptions.{BusRoutes, Lines}

  def replace_stops(trip_options, params) do
    stations = String.split(params["stops"], ",", trim: true)
    put_in trip_options.stations, stations
  end

  def add_station_selection(trip_options, params) do
    stations = add_station_to_list(params)
    put_in trip_options.stations, stations
  end

  def remove_station_selection(trip_options, params) do
    stations = remove_station_from_list(params, params["station"])
    put_in trip_options.stations, stations
  end

  def add_station_to_list(sub_params) do
    stations = String.split(sub_params["stops"], ",", trim: true)
    [sub_params["station"] | stations]
    |> Enum.map(&fetch_stop_from_cache/1)
    |> Enum.uniq()
  end

  def add_route_to_list(%{"routes" => ""}), do: []
  def add_route_to_list(%{"routes" => routes} = sub_params) when not is_nil(routes) do
    routes = String.split(sub_params["routes"], ",", trim: true)
    sub_params
    |> do_add_route_to_list(routes)
    |> Enum.uniq()
    |> Enum.map(&fetch_route_from_cache/1)
    |> Enum.map(&BusRoutes.route_list_select_option(elem(&1, 0), elem(&1, 1)))
  end
  def add_route_to_list(_), do: []


  defp do_add_route_to_list(%{"route" => route}, routes) when not is_nil(route), do: [route | routes]
  defp do_add_route_to_list(_, routes), do: routes

  def remove_station_from_list(sub_params, station) do
    sub_params["stops"]
    |> String.split(",", trim: true)
    |> Kernel.--([station])
    |> Enum.map(&fetch_stop_from_cache/1)
  end

  def remove_route_from_list(sub_params, route) do
    sub_params["routes"]
    |> String.split(",", trim: true)
    |> Kernel.--([route])
    |> Enum.map(&fetch_route_from_cache/1)
    |> Enum.map(&BusRoutes.route_list_select_option(elem(&1, 0), elem(&1, 1)))
  end

  def station_options(cr_stations, subway_stations) do
    subway_stations
    |> Kernel.++(cr_stations)
    |> Lines.station_list_select_options()
  end

  defp fetch_stop_from_cache(stop) do
    {:ok, stop} = ServiceInfoCache.get_stop(stop)
    stop
  end

  defp fetch_route_from_cache(route) do
    [route, direction] = String.split(route, " - ")
    {:ok, route} = ServiceInfoCache.get_route(route)
    {route, direction}
  end
end
