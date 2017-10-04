defmodule AlertProcessor.ServiceInfoCache do
  @moduledoc """
  Module used to keep track of and periodically fetch
  service information such as route maps grouped by
  mode, line, then branch.
  """
  use GenServer
  alias AlertProcessor.Helpers.{ConfigHelper, StringHelper}
  alias AlertProcessor.{ApiClient, Model.Route}
  require Logger

  @service_types [:bus, :commuter_rail, :ferry, :subway]
  @info_types [:parent_stop_info, :subway_full_routes, :ferry_general_ids, :commuter_rail_trip_ids, :facility_map]

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @doc """
  Initialize GenServer and schedule recurring service info fetching.
  """
  def init(_) do
    {:ok, fetch_and_cache_service_info()}
  end

  def get_subway_info(name \\ __MODULE__) do
    GenServer.call(name, :get_subway_info)
  end

  def get_subway_full_routes(name \\ __MODULE__) do
    GenServer.call(name, :get_subway_full_routes)
  end

  def get_bus_info(name \\ __MODULE__) do
    GenServer.call(name, :get_bus_info)
  end

  def get_commuter_rail_info(name \\ __MODULE__) do
    GenServer.call(name, :get_commuter_rail_info)
  end

  def get_ferry_info(name \\ __MODULE__) do
    GenServer.call(name, :get_ferry_info)
  end

  def get_stop(name \\ __MODULE__, stop_id) do
    GenServer.call(name, {:get_stop, stop_id})
  end

  def get_stop_by_name(name \\ __MODULE__, stop_name) do
    GenServer.call(name, {:get_stop_by_name, stop_name})
  end

  def get_direction_name(name \\ __MODULE__, route, direction_id) do
    GenServer.call(name, {:get_direction_name, route, direction_id})
  end

  def get_headsign(name \\ __MODULE__, origin, destination, direction_id) do
    GenServer.call(name, {:get_headsign, origin, destination, direction_id})
  end

  def get_route(name \\ __MODULE__, route) do
    GenServer.call(name, {:get_route, route})
  end

  def get_parent_stop_id(name \\ __MODULE__, stop_id) do
    GenServer.call(name, {:get_parent_stop_id, stop_id})
  end

  def get_generalized_trip_id(name \\ __MODULE__, trip_id) do
    GenServer.call(name, {:get_generalized_trip_id, trip_id})
  end

  def get_trip_name(name \\ __MODULE__, trip_id) do
    GenServer.call(name, {:get_trip_name, trip_id})
  end

  def get_facility_map(name \\ __MODULE__) do
    GenServer.call(name, :get_facility_map)
  end

  @doc """
  Update service info and then reschedule next time to process.
  """
  def handle_info(:work, _) do
    schedule_work()
    service_info_cache = fetch_and_cache_service_info()
    Logger.info("Service info cache refreshed")
    {:noreply, service_info_cache}
  end

  def handle_call(:get_subway_info, _from, %{routes: route_state} = state) do
    subway_state = Enum.filter(route_state, fn(%{route_type: route_type}) -> route_type == 0 || route_type == 1 end)
    {:reply, {:ok, subway_state}, state}
  end

  def handle_call(:get_subway_full_routes, _from, %{subway_full_routes: subway_full_routes_state} = state) do
    {:reply, {:ok, subway_full_routes_state}, state}
  end

  def handle_call(:get_bus_info, _from, %{routes: route_state} = state) do
    bus_state = Enum.filter(route_state, fn(%{route_type: route_type}) -> route_type == 3 end)
    {:reply, {:ok, bus_state}, state}
  end

  def handle_call(:get_commuter_rail_info, _from, %{routes: route_state} = state) do
    commuter_rail_state = Enum.filter(route_state, fn(%{route_type: route_type}) -> route_type == 2 end)
    {:reply, {:ok, commuter_rail_state}, state}
  end

  def handle_call(:get_ferry_info, _from, %{routes: route_state} = state) do
    ferry_state = Enum.filter(route_state, fn(%{route_type: route_type}) -> route_type == 4 end)
    {:reply, {:ok, ferry_state}, state}
  end

  def handle_call({:get_stop, stop_id}, _from, %{routes: route_state} = state) do
    stop = get_stop_from_state(stop_id, route_state)
    {:reply, {:ok, stop}, state}
  end

  def handle_call({:get_stop_by_name, stop_name}, _from, %{routes: route_state} = state) do
    stop = get_stop_from_state_by_name(stop_name, route_state)
    {:reply, {:ok, stop}, state}
  end

  def handle_call({:get_direction_name, route, direction_id}, _from, %{routes: route_state} = state) do
    case Enum.find(route_state, fn(%{route_id: route_id}) -> route_id == route end) do
      %{direction_names: direction_names} ->
        {:reply, {:ok, Enum.at(direction_names, direction_id)}, state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:get_headsign, origin, destination, direction_id}, _from, %{routes: route_state} = state) do
    relevant_routes =
      route_state
      |> Enum.filter(fn(%Route{stop_list: stop_list}) -> List.keymember?(stop_list, origin, 0) && List.keymember?(stop_list, destination, 0) end)

    case relevant_routes do
      [] -> {:reply, :error, state}
      relevant_routes -> {:reply, {:ok, parse_headsign(relevant_routes, direction_id)}, state}
    end
  end

  def handle_call({:get_route, route}, _from, %{routes: route_state} = state) do
    route = Enum.find(route_state, fn(%{route_id: route_id}) -> route_id == route end)
    {:reply, {:ok, route}, state}
  end

  def handle_call({:get_parent_stop_id, stop_id}, _from, %{parent_stop_info: parent_stop_info} = state) do
    parent_stop_id = Map.get(parent_stop_info, stop_id)
    {:reply, {:ok, parent_stop_id}, state}
  end

  def handle_call({:get_generalized_trip_id, trip_id}, _from, %{ferry_general_ids: ferry_general_ids} = state) do
    generalized_trip_id = Map.get(ferry_general_ids, trip_id)
    {:reply, {:ok, generalized_trip_id}, state}
  end

  def handle_call({:get_trip_name, trip_id}, _from, %{commuter_rail_trip_ids: commuter_rail_trip_ids} = state) do
    trip_name = Map.get(commuter_rail_trip_ids, trip_id)
    {:reply, {:ok, trip_name}, state}
  end

  def handle_call(:get_facility_map, _from, %{facility_map: facility_map} = state) do
    {:reply, {:ok, facility_map}, state}
  end

  defp parse_headsign(relevant_routes, direction_id) do
    case relevant_routes do
      [%Route{route_id: "Green-" <> _} | _t] ->
        relevant_routes
        |> Enum.map(& String.replace(&1.route_id, ~r/(.+)-/, ""))
        |> StringHelper.or_join()
      _ ->
        case direction_id do
          0 -> select_headsign(relevant_routes, &List.first/1)
          1 -> select_headsign(relevant_routes, &List.last/1)
        end
    end
  end

  defp select_headsign(relevant_routes, selector_func) do
    relevant_routes
    |> Enum.map(fn(%Route{stop_list: stop_list}) ->
        stop_list |> selector_func.() |> elem(0)
      end)
    |> Enum.uniq()
    |> StringHelper.or_join()
  end

  defp get_stop_from_state(stop_id, state) do
    Enum.find_value(state, fn(%Route{stop_list: stop_list}) ->
      Enum.find(stop_list, fn({_name, id}) ->
        id == stop_id
      end)
    end)
  end

  defp get_stop_from_state_by_name(stop_name, state) do
    Enum.find_value(state, fn(%Route{stop_list: stop_list}) ->
      Enum.find(stop_list, fn({name, _id}) ->
        name == stop_name
      end)
    end)
  end

  defp fetch_and_cache_service_info do
    route_state =
      Enum.flat_map(@service_types, fn(service_type) ->
        fetch_service_info(service_type)
      end)
    for info_type <- @info_types, into: %{routes: route_state} do
      {info_type, fetch_service_info(info_type)}
    end
  end

  defp fetch_service_info(:subway_full_routes), do: fetch_subway({:split_red_line_branches, false})
  defp fetch_service_info(:subway), do: fetch_subway({:split_red_line_branches, true})
  defp fetch_service_info(:commuter_rail), do: do_fetch_service_info([2])
  defp fetch_service_info(:ferry), do: do_fetch_service_info([4])
  defp fetch_service_info(:bus), do: do_fetch_service_info([3])
  defp fetch_service_info(:parent_stop_info) do
    {:ok, parent_stations} = ApiClient.parent_stations()
    for station <- parent_stations, into: %{} do
      case station do
        %{"id" => id, "relationships" => %{"parent_station" => %{"data" => nil}}} ->
          {id, id}
        %{"id" => id, "relationships" => %{"parent_station" => %{"data" => %{"id" => parent_station_id}}}} ->
          {id, parent_station_id}
      end
    end
  end
  defp fetch_service_info(:ferry_general_ids) do
    {:ok, routes} = ApiClient.routes([4])
    route_ids = Enum.map(routes, & &1["id"])
    {:ok, trips, service_info} = ApiClient.trips_with_service_info(route_ids)
    trip_info_map = map_trip_information(trips, service_info)
    trip_ids = Enum.map(trips, & &1["id"])

    for trip_id <- trip_ids, into: %{} do
      {:ok, schedules} = ApiClient.schedule_for_trip(trip_id)
      [departure_schedule | _t] = Enum.sort_by(schedules, & &1["attributes"]["departure_time"])
      %{"relationships" => %{"stop" => %{"data" => %{"id" => origin_id}}}, "attributes" => %{"departure_time" => departure_timestamp}} = departure_schedule
      departure_time = departure_timestamp |> NaiveDateTime.from_iso8601!() |> NaiveDateTime.to_time()
      {trip_id, map_generalized_trip_id(trip_id, trip_info_map, %{origin_id: origin_id, departure_time: departure_time})}
    end
  end
  defp fetch_service_info(:commuter_rail_trip_ids) do
    {:ok, routes} = ApiClient.routes([2])
    route_ids = Enum.map(routes, & &1["id"])
    {:ok, trips, _} = ApiClient.trips_with_service_info(route_ids)

    for trip <- trips, into: %{} do
      %{"attributes" => %{"name" => name}, "id" => trip_id} = trip
      {trip_id, name}
    end
  end
  defp fetch_service_info(:facility_map) do
    {:ok, facilities} = ApiClient.facilities()

    for f <- facilities, into: %{} do
      %{"attributes" => %{"type" => facility_type}, "id" => id} = f
      {id, facility_type}
    end
  end

  defp map_trip_information(trips, service_info) do
    service_valid_days_map =
      Map.new(service_info, fn(%{"id" => service_id, "attributes" => %{"valid_days" => valid_days}}) ->
        {service_id, valid_days}
      end)

    Map.new(trips, fn(%{
        "id" => trip_id,
        "relationships" => %{
          "service" => %{"data" => %{"id" => trip_service_id}},
          "route" => %{"data" => %{"id" => route_id}}
        },
        "attributes" => %{"direction_id" => direction_id}
      }) ->
      {trip_id, %{route_id: route_id, direction_id: direction_id, valid_days: Map.get(service_valid_days_map, trip_service_id)}}
    end)
  end

  defp map_generalized_trip_id(trip_id, trip_info_map, departure_info_map) do
    %{route_id: route_id, direction_id: direction_id, valid_days: valid_days} = Map.get(trip_info_map, trip_id)
    %{origin_id: origin_id, departure_time: departure_time} = departure_info_map
    Enum.join([
      route_id,
      origin_id,
      departure_time,
      parse_time_of_week(valid_days),
      direction_id
    ], "-")
  end

  defp parse_time_of_week([1, 2, 3, 4, 5]), do: "weekday"
  defp parse_time_of_week([5]), do: "friday"
  defp parse_time_of_week([6]), do: "saturday"
  defp parse_time_of_week([7]), do: "sunday"
  defp parse_time_of_week([6, 7]), do: "weekend"
  defp parse_time_of_week(_), do: "weekday"

  defp do_fetch_service_info(route_types) do
    {:ok, routes} = ApiClient.routes(route_types)
    routes
    |> Enum.map(
      fn(%{"attributes" => %{"type" => route_type, "long_name" => long_name, "short_name" => short_name, "direction_names" => direction_names}, "id" => id}) ->
          {id, route_type, long_name, short_name, direction_names}
      end)
    |> Enum.with_index()
    |> Enum.map(&map_route_struct/1)
  end

  defp map_route_struct({{route_id, route_type, long_name, short_name, direction_names}, index}) do
    %Route{
      route_id: route_id,
      long_name: long_name,
      short_name: short_name,
      route_type: route_type,
      direction_names: direction_names,
      order: index,
      stop_list: fetch_stops(route_type, route_id),
      headsigns: fetch_headsigns(route_type, route_id)
    }
  end

  defp fetch_stops(3, _), do: []
  defp fetch_stops(_route_type, route_id) do
    {:ok, route_stops} = ApiClient.route_stops(route_id)

    route_stops
    |> Enum.map(fn(%{"attributes" => %{"name" => name}, "id" => id}) ->
      {name, id}
    end)
  end

  defp fetch_headsigns(3, route_id) do
    [zero_task, one_task] =
      for direction_id <- [0, 1] do
        Task.async(__MODULE__, :do_headsigns, [route_id, direction_id])
      end
    %{0 => Task.await(zero_task), 1 => Task.await(one_task)}
  end
  defp fetch_headsigns(_, _), do: nil

  defp fetch_subway({:split_red_line_branches, split_red_line_branches}) do
    [0, 1]
    |> do_fetch_service_info()
    |> Enum.flat_map(fn(route) ->
      route.route_id
      |> fetch_route_branches()
      |> handle_red_line_branches(route, split_red_line_branches)
    end)
  end

  defp handle_red_line_branches(_branches, route, false), do: [route]
  defp handle_red_line_branches([], route, true), do: [route]
  defp handle_red_line_branches(branches, route, true) do
    parse_branches(route, route.stop_list, branches)
  end

  defp fetch_route_branches("Red") do
    {:ok, route_shapes} = ApiClient.route_shapes("Red")

    Enum.map(route_shapes, fn(%{"relationships" => %{"stops" => %{"data" => stops}}}) ->
      Enum.map(stops, & &1["id"])
    end)
  end
  defp fetch_route_branches(_), do: []

  defp parse_branches(route, stop_list, branches) do
    Enum.map(branches, fn(branch) ->
      stops = Enum.filter(stop_list, fn({_name, stop_id}) -> Enum.member?(branch, stop_id) end)
      Map.put(route, :stop_list, stops)
    end)
  end

  def do_headsigns(route_id, direction_id) do
    {:ok, trips} = ApiClient.trips(route_id, direction_id)

    trips
    |> Enum.filter(fn %{"attributes" => attributes} -> attributes["headsign"] != "" end)
    |> Enum.map(fn %{"attributes" => attributes} -> attributes["headsign"] end)
    |> order_headsigns_by_frequency()
  end

  defp order_headsigns_by_frequency(trips) do
    # the complicated function in the middle collapses some lengths which are
    # close together and allows us to instead sort by the name.  For example,
    # on the Red line, Braintree has 649 trips, Ashmont has 647.  The
    # division by -4 with a round makes them both -162 and so equal.  We
    # divide by -4 so that the ordering by count is large to small, but the
    # name ordering is small to large.
    trips
    |> Enum.group_by(&(&1))
    |> Enum.sort_by(fn({value, values}) -> {values |> length |> (fn v -> Float.round(v / -4) end).(), value} end)
    |> Enum.map(&(elem(&1, 0)))
  end

  defp schedule_work do
    Process.send_after(self(), :work, update_interval())
  end

  defp update_interval do
    ConfigHelper.get_int(:service_info_update_interval)
  end
end
