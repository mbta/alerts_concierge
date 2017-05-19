defmodule AlertProcessor.ServiceInfoCache do
  @moduledoc """
  Module used to keep track of and periodically fetch
  service information such as route maps grouped by
  mode, line, then branch.
  """
  use GenServer
  alias AlertProcessor.Helpers.ConfigHelper
  alias AlertProcessor.ApiClient

  @service_map %{
    subway: ["Blue", "Green-B", "Green-C", "Green-D", "Green-E", "Mattapan", "Orange", "Red"]
  }

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
    for {service, routes} <- @service_map, into: %{} do
      {service, fetch_route_info(routes)}
    end
  end

  defp fetch_route_info(routes) do
    for route <- routes, into: %{} do
      stop_list = Enum.map(ApiClient.route_stops(route), fn(%{"attributes" => %{"name" => name}, "id" => id}) ->
        {name, id}
      end)
      {route, stop_list}
    end
  end

  defp schedule_work do
    Process.send_after(self(), :work, filter_interval())
  end

  defp filter_interval do
    ConfigHelper.get_int(:service_info_update_interval)
  end
end
