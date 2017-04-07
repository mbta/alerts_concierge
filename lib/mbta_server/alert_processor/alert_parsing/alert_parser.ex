defmodule MbtaServer.AlertProcessor.AlertParser do
  @moduledoc """
  Module used to parse alerts from api and transform into Alert structs and pass along
  relevant information to subscription filter engine.
  """
  alias MbtaServer.AlertProcessor.{AlertCache, ApiClient, SubscriptionFilterEngine}

  @doc """
  process_alerts/0 entry point for fetching json data from api and, transforming, storing and passing to
  subscription engine to process before sending.
  """
  @spec process_alerts() :: [:ok | :error] | String.t
  def process_alerts() do
    case ApiClient.get_alerts do
      {:error, message} ->
        message
      alert_data ->
        alerts = Enum.reduce(alert_data, %{}, &parse_alert/2)
        {new_alerts, _} = AlertCache.update_cache(:alert_cache, alerts)
        Enum.map(new_alerts, &SubscriptionFilterEngine.process_alert/1)
    end
  end

  @spec parse_alert(map, map) :: [%{String.t => %{header: String.t, alert_id: String.t}}]
  defp parse_alert(%{"attributes" => %{"header" => header}, "id" => alert_id}, accumulator) when is_binary(header) do
    Map.put(accumulator, alert_id, %{header: header, alert_id: alert_id})
  end

  defp parse_alert(_, accumulator) do
    accumulator
  end
end
