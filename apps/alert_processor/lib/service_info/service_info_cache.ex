defmodule AlertProcessor.ServiceInfoCache do
  @moduledoc """
  Module used to keep track of and periodically fetch
  service information such as route maps grouped by
  mode, line, then branch.
  """
  use GenServer
  alias AlertProcessor.Helpers.{ConfigHelper, StringHelper}
  alias AlertProcessor.{ApiClient, Model.Route}

  @service_types [:bus, :subway]
  @info_types [:parent_stop_info, :subway_full_routes]

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @doc """
  Initialize GenServer and schedule recurring service info fetching.
  """
  def init(_) do
    {:ok, fetch_service_info()}
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

  def get_stop(name \\ __MODULE__, mode, stop_id) do
    GenServer.call(name, {:get_stop, mode, stop_id})
  end

  def get_direction_name(name \\ __MODULE__, route_type, route, direction_id) do
    GenServer.call(name, {:get_direction_name, route_type, route, direction_id})
  end

  def get_headsign(name \\ __MODULE__, route_type, origin, destination, direction_id) do
    GenServer.call(name, {:get_headsign, route_type, origin, destination, direction_id})
  end

  def get_route(name \\ __MODULE__, route) do
    GenServer.call(name, {:get_route, route})
  end

  def get_parent_stop_id(name \\ __MODULE__, stop_id) do
    GenServer.call(name, {:get_parent_stop_id, stop_id})
  end

  @doc """
  Update service info and then reschedule next time to process.
  """
  def handle_info(:work, _) do
    schedule_work()
    {:noreply, fetch_service_info()}
  end

  def handle_call(:get_subway_info, _from, %{subway: subway_state} = state) do
    {:reply, {:ok, subway_state}, state}
  end

  def handle_call(:get_subway_full_routes, _from, %{subway_full_routes: subway_full_routes_state} = state) do
    {:reply, {:ok, subway_full_routes_state}, state}
  end

  def handle_call(:get_bus_info, _from, %{bus: bus_state} = state) do
    {:reply, {:ok, bus_state}, state}
  end

  def handle_call({:get_stop, :subway, stop_id}, _from, %{subway: subway_state} = state),
    do: {:reply, {:ok, get_stop_from_state(stop_id, subway_state)}, state}

  def handle_call({:get_direction_name, :subway, route, direction_id}, _from, %{subway: subway_state} = state) do
    case Enum.find(subway_state, fn(%{route_id: route_id}) -> route_id == route end) do
      %{direction_names: direction_names} ->
        {:reply, {:ok, Enum.at(direction_names, direction_id)}, state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:get_headsign, :subway, origin, destination, direction_id}, _from, %{subway: subway_state} = state) do
    relevant_routes =
      subway_state
      |> Enum.filter(fn(%Route{stop_list: stop_list}) -> List.keymember?(stop_list, origin, 0) && List.keymember?(stop_list, destination, 0) end)

    case relevant_routes do
      [] -> {:reply, :error, state}
      relevant_routes -> {:reply, {:ok, parse_headsign(relevant_routes, direction_id)}, state}
    end
  end

  def handle_call({:get_route, route_id}, _from, state) do
    route =
      @service_types
      |> Enum.flat_map(& Map.get(state, &1))
      |> Enum.find(& &1.route_id == route_id)
    {:reply, {:ok, route}, state}
  end

  def handle_call({:get_parent_stop_id, stop_id}, _from, %{parent_stop_info: parent_stop_info} = state) do
    parent_stop_id = Map.get(parent_stop_info, stop_id)
    {:reply, {:ok, parent_stop_id}, state}
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

  defp fetch_service_info do
    for info_type <- @info_types, into: %{} do
      {info_type, fetch_service_info(info_type)}
    end
  end

  defp fetch_service_info(:parent_stop_info) do
    for subway_stop <- ApiClient.subway_parent_stops(), into: %{} do
      %{"id" => id, "relationships" => %{"parent_station" => %{"data" => %{"id" => parent_station_id}}}} = subway_stop
      {id, parent_station_id}
    end
  end

  defp fetch_service_info(:subway_full_routes) do
    fetch_subway({:split_red_line_branches, false})
  end

  defp fetch_service_info(:subway) do
    fetch_subway({:split_red_line_branches, true})
  end

  defp fetch_service_info(:bus) do
    [3]
    |> do_fetch_service_info()
    |> Enum.map(fn({route_id, route_type, long_name, direction_names}) ->
      [zero_task, one_task] =
        for direction_id <- [0, 1] do
          Task.async(__MODULE__, :do_headsigns, [route_id, direction_id])
        end
      %Route{
        route_id: route_id,
        long_name: long_name,
        route_type: route_type,
        direction_names: direction_names,
        headsigns: %{0 => Task.await(zero_task), 1 => Task.await(one_task)}
      }
    end)
  end

  defp do_fetch_service_info(route_types) do
    route_types
    |> ApiClient.routes()
    |> Enum.map(
        fn(%{"attributes" => %{"type" => route_type, "long_name" => long_name, "direction_names" => direction_names}, "id" => id}) ->
          case long_name do
            "" -> {id, route_type, id, direction_names}
            _ -> {id, route_type, long_name, direction_names}
          end
      end)
  end

  defp fetch_subway({:split_red_line_branches, split_red_line_branches}) do
    [0, 1]
    |> do_fetch_service_info()
    |> Enum.flat_map(fn({route_id, route_type, long_name, direction_names}) ->
      stop_list =
        route_id
        |> ApiClient.route_stops
        |> Enum.map(fn(%{"attributes" => %{"name" => name}, "id" => id}) ->
          {name, id}
        end)
      route = %Route{route_id: route_id, long_name: long_name, route_type: route_type, direction_names: direction_names, stop_list: stop_list}
      fetch_route_branches(route_id)
      |> handle_red_line_branches(route, split_red_line_branches)
    end)
  end

  defp handle_red_line_branches(_branches, route, false), do: [route]
  defp handle_red_line_branches([], route, true), do: [route]
  defp handle_red_line_branches(branches, route, true) do
    parse_branches(route, route.stop_list, branches)
  end

  defp fetch_route_branches("Red") do
    "Red"
    |> ApiClient.route_shapes()
    |> Enum.map(fn(%{"relationships" => %{"stops" => %{"data" => stops}}}) ->
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
    route_id
    |> ApiClient.trips(direction_id)
    |> Enum.filter_map(
        fn %{"attributes" => attributes} -> attributes["headsign"] != "" end,
        fn %{"attributes" => attributes} -> attributes["headsign"] end
      )
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
