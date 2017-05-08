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

  def handle_call({:update_cache, new_alerts}, _from, %{alerts: old_alerts}) do
    removed_alert_ids =  Map.keys(old_alerts) -- Map.keys(new_alerts)
    {unchanged_alerts, updated_alerts} = segment_alerts(new_alerts,
                                                        old_alerts,
                                                        removed_alert_ids)
    response = {unchanged_alerts,
                removed_alert_ids,
                updated_alerts}
    {:reply, response, %{alerts: new_alerts}}
  end

  defp alerts_list(alerts) do
    Map.values(alerts)
  end

  defp segment_alerts(new_alerts, old_alerts, removed_alert_ids) do
    new = alerts_list(new_alerts)

    updated_alerts = old_alerts
    |> alerts_list
    |> without_removed(removed_alert_ids)
    |> pair_by_id(new)
    |> find_updated_alerts

    {new -- updated_alerts, updated_alerts}
  end

  defp find_updated_alerts(alerts) do
    Enum.reduce(alerts, [], fn({old_alert, new_alert}, acc) ->
      if updated?(new_alert, old_alert) do
        acc ++ [new_alert]
      else
        acc
      end
    end)
  end

  defp without_removed(alerts, ids) do
    Enum.filter(alerts, fn(old_alert) ->
      !Enum.member?(ids, old_alert.id)
    end)
  end

  defp pair_by_id(alerts, new_alerts) do
    Enum.map(alerts, fn(alert) ->
      matching_new = Enum.find(new_alerts, fn(x) -> x.id == alert.id end)
      if matching_new != nil do
        {alert, matching_new}
      end
    end)
  end

  defp updated?(new_alert, old_alert) do
    updated_value(new_alert) != updated_value(old_alert)
  end

  defp updated_value(alert) do
    if Map.has_key?(alert, :updated_at) do
      alert.updated_at
    else
      nil
    end
  end
end
