defmodule MbtaServer.AlertProcessor.AlertCache do
  @moduledoc """
  Module used to store alerts retrieved from api. On update returns list of new alerts
  as well as a list of removed alerts from previous set of alerts.
  """
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, [{:alerts, %{}}], [name: name])
  end

  @spec update_cache(atom, Map) :: {[{String.t, Map}], [{String.t, Map}]}
  def update_cache(name, alerts) do
    GenServer.call(name, {:update_cache, alerts})
  end

  def init(args) do
    [{:alerts, alerts}] = args
    {:ok, %{alerts: alerts}}
  end

  def handle_call({:update_cache, new_alerts}, _from, state) do
    %{alerts: old_alerts} = state
    removed_alert_keys =  Map.keys(old_alerts) -- Map.keys(new_alerts)
    removed_alerts = Map.take(old_alerts, removed_alert_keys)
    response = {Enum.to_list(new_alerts), Enum.to_list(removed_alerts)}
    {:reply, response, %{alerts: new_alerts}}
  end
end
