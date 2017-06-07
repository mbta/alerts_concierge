defmodule AlertProcessor.ServiceInfoCache do
  @moduledoc """
  Module used to keep track of and periodically fetch
  service information such as route maps grouped by
  mode, line, then branch.
  """
  use GenServer
  alias AlertProcessor.Helpers.{ConfigHelper, StringHelper}
  alias AlertProcessor.{ApiClient, Model.Route}

  @services [:bus, :subway]

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

  defp parse_headsign(relevant_routes, direction_id) do
    case relevant_routes do
      [%Route{route_id: "Green-" <> _} | _t] ->
        relevant_routes
        |> Enum.map(& String.replace(&1.route_id, ~r/(.+)-/, ""))
        |> StringHelper.or_join()
      _ ->
      case direction_id do
        1 ->
          relevant_routes
          |> Enum.map(fn(%Route{stop_list: stop_list}) ->
              stop_list |> List.last() |> elem(0)
            end)
          |> Enum.uniq()
          |> Enum.join(", ")
        0 ->
          relevant_routes
          |> Enum.map(fn(%Route{stop_list: stop_list}) ->
              stop_list |> List.first() |> elem(0)
            end)
          |> Enum.uniq()
          |> Enum.join(", ")
      end
    end
  end

  defp get_stop_from_state(stop_id, state) do
    Enum.find_value(state, fn(%Route{stop_list: stop_list}) ->
      Enum.find(stop_list, fn({_name, id}) ->
        id == stop_id
      end)
    end)
  end

  defp fetch_service_info do
    for service <- @services, into: %{} do
      {service, fetch_service_info(service)}
    end
  end

  defp fetch_service_info(:subway) do
    routes =
      [0, 1]
      |> ApiClient.routes()
      |> Enum.filter_map(
          fn(%{"attributes" => %{"type" => route_type}}) -> route_type <= 1 end,
          fn(%{"attributes" => %{"type" => route_type, "long_name" => long_name, "direction_names" => direction_names}, "id" => id}) -> {id, route_type, long_name, direction_names}
        end)

    Enum.flat_map(routes, fn({route_id, route_type, long_name, direction_names}) ->
      stop_list =
        route_id
        |> ApiClient.route_stops
        |> Enum.map(fn(%{"attributes" => %{"name" => name}, "id" => id}) ->
          {name, id}
        end)
      case fetch_route_branches(route_id) do
        [] ->
          [%Route{route_id: route_id, long_name: long_name, route_type: route_type, direction_names: direction_names, stop_list: stop_list}]
        branches ->
          parse_branches(%Route{route_id: route_id, long_name: long_name, route_type: route_type, direction_names: direction_names}, stop_list, branches)
      end
    end)
  end

  defp fetch_service_info(:bus) do
    for route_id <- fetch_bus_routes(), into: %{} do
      [zero_task, one_task] =
        for direction_id <- [0, 1] do
          Task.async(__MODULE__, :do_headsigns, [route_id, direction_id])
        end
      {route_id, %{
        0 => Task.await(zero_task),
        1 => Task.await(one_task)
      }}
    end
  end

  defp fetch_route_branches("Red") do
    ApiClient.route_shapes("Red")
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

  defp fetch_bus_routes do
    Enum.filter_map(ApiClient.routes([3]), fn(%{"attributes" => %{"type" => route_type}}) -> route_type == 3 end, &(&1["id"]))
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
