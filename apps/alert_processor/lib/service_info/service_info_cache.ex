defmodule AlertProcessor.ServiceInfoCache do
  @moduledoc """
  Module used to keep track of and periodically fetch
  service information such as route maps grouped by
  mode, line, then branch.
  """
  use GenServer
  alias AlertProcessor.Helpers.ConfigHelper
  alias AlertProcessor.{ApiClient, Model.Route}

  @services [:subway]

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @doc """
  Initialize GenServer and schedule recurring service info fetching.
  """
  def init(_) do
    send self(), :work
    {:ok, %{}}
  end

  def get_subway_info(name \\ __MODULE__) do
    GenServer.call(name, :get_subway_info)
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

  defp fetch_service_info do
    for service <- @services, into: %{} do
      {service, fetch_route_info(service)}
    end
  end

  defp fetch_route_info(:subway) do
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

  defp schedule_work do
    Process.send_after(self(), :work, update_interval())
  end

  defp update_interval do
    ConfigHelper.get_int(:service_info_update_interval)
  end
end
