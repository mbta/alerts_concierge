defmodule MbtaServer.AlertProcessor.AlertCache do
  @moduledoc """
  Module used to store alerts retrieved from api. On update returns list of new alerts
  as well as a list of removed alerts from previous set of alerts.
  """
  use GenServer

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @doc """
  update_cache/2 takes the name of the cache and a map of alerts.
  On update, the current cached alerts are retrieved and diffed against the new set of alerts
  which are then stored. Returned is a tuple containing a list of new alerts to be processed,
  and a list of removed alert ids to be removed from the holding queue since the alert is no
  longer active.
  """
  @spec update_cache(atom, map) :: {[map], [String.t]}
  def update_cache(name \\ __MODULE__, alerts) do
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
    Map.values(alerts)
  end
end
