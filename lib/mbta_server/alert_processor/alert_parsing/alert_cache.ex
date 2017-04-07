defmodule MbtaServer.AlertProcessor.AlertCache do
  @moduledoc """
  Module used to store alerts retrieved from api. On update returns list of new alerts
  as well as a list of removed alerts from previous set of alerts.
  """
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @spec update_cache(atom, map) :: {[{String.t, map}], [{String.t, map}]}
  def update_cache(name, alerts) do
    GenServer.call(name, {:update_cache, alerts})
  end

  def init(_) do
    {:ok, %{alerts: %{}}}
  end

  def handle_call({:update_cache, new_alerts}, _from, state) do
    %{alerts: old_alerts} = state
    removed_alert_ids =  Map.keys(old_alerts) -- Map.keys(new_alerts)
    response = {new_alerts_list(new_alerts), removed_alert_ids}
    {:reply, response, %{alerts: new_alerts}}
  end

  defp new_alerts_list(alerts) do
    Enum.map(alerts, fn({_id, alert}) -> alert end)
  end
end
