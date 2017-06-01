defmodule AlertProcessor.ServiceInfoCache do
  @moduledoc """
  Module used to keep track of and periodically fetch
  service information such as route maps grouped by
  mode, line, then branch.
  """
  use GenServer
  alias AlertProcessor.Helpers.ConfigHelper
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

  defp fetch_service_info do
    for service <- @services, into: %{} do
      {service, fetch_service_info(service)}
    end
  end

  defp fetch_service_info(:subway) do
    routes =
      ["0", "1"]
      |> ApiClient.routes()
      |> Enum.filter_map(
          fn(%{"attributes" => %{"type" => route_type}}) -> route_type <= 1 end,
          fn(%{"attributes" => %{"type" => route_type, "direction_names" => direction_names}, "id" => id}) -> {id, route_type, direction_names}
        end)

    for {route_id, route_type, direction_names} <- routes, into: [] do
      stop_list =
        route_id
        |> ApiClient.route_stops
        |> Enum.map(fn(%{"attributes" => %{"name" => name}, "id" => id}) ->
          {name, id}
        end)
      %Route{route_id: route_id, route_type: route_type, direction_names: direction_names, stop_list: stop_list}
    end
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
