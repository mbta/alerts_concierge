defmodule MbtaServer.AlertProcessor.AlertParser do
  @moduledoc """
  Module used to parse alerts from api and transform into Alert structs and pass along
  relevant information to subscription filter engine.
  """
  alias MbtaServer.AlertProcessor.{AlertCache, ApiClient, HoldingQueue, Parser, SubscriptionFilterEngine}
  alias MbtaServer.AlertProcessor.Model.Alert

  @behaviour Parser

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
        {new_alerts, removed_alert_ids} =
          alert_data
          |> Enum.reduce(%{}, &parse_alert/2)
          |> AlertCache.update_cache()
        HoldingQueue.remove_notifications(removed_alert_ids)
        Enum.map(new_alerts, &SubscriptionFilterEngine.process_alert/1)
    end
  end

  @spec parse_alert(map, map) :: [%{String.t => Alert.t}]
  defp parse_alert(
    %{
      "attributes" => %{
        "effect_name" => effect_name,
        "header" => header,
        "informed_entity" => informed_entities,
        "severity" => severity
      },
      "id" => alert_id
    }, accumulator
  ) when is_binary(header) do
    Map.put(
      accumulator,
      alert_id,
      struct(Alert, %{
        id: alert_id,
        effect_name: effect_name,
        header: header,
        informed_entities: informed_entities,
        severity: severity |> String.downcase |> String.to_existing_atom
      })
    )
  end

  defp parse_alert(_, accumulator) do
    accumulator
  end
end
