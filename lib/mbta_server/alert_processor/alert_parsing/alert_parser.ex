defmodule MbtaServer.AlertProcessor.AlertParser do
  @moduledoc """
  Module used to parse alerts from api and transform into Alert structs and pass along
  relevant information to subscription filter engine.
  """
  alias MbtaServer.AlertProcessor.{AlertCache, ApiClient, HoldingQueue, Parser, SubscriptionFilterEngine}
  alias MbtaServer.AlertProcessor.Model.{Alert, Notification}

  @behaviour Parser

  @doc """
  process_alerts/0 entry point for fetching json data from api and, transforming, storing and passing to
  subscription engine to process before sending.
  """
  @spec process_alerts() :: [{:ok, [Notification.t]}]
  def process_alerts() do
    case ApiClient.get_alerts do
      {:error, message} ->
        message
      alert_data ->
        {new_alerts, removed_alert_ids, updated_alerts} =
          alert_data
          |> map_facilities()
          |> parse_alerts()
          |> AlertCache.update_cache()

        HoldingQueue.remove_notifications(removed_alert_ids)

        updated_alerts
        |> Enum.map(&(&1[:id]))
        |> HoldingQueue.remove_notifications

        Enum.map(new_alerts ++ updated_alerts, &SubscriptionFilterEngine.process_alert/1)
   end
  end

  defp map_facilities({alerts, facilities}) do
    facilities_map = for f <- facilities, into: %{} do
      %{"attributes" => %{"type" => facility_type}, "id" => id} = f
      {id, facility_type}
    end
    {alerts, facilities_map}
  end

  defp parse_alerts({alerts, facilities_map}) do
    Enum.reduce(alerts, %{}, fn(x, acc) ->
      parse_alert(x, facilities_map, acc)
    end)
  end

  @spec parse_alert(map, [map], map) :: [%{String.t => Alert.t}]
  defp parse_alert(
    %{
      "attributes" => %{
        "active_period" => active_periods,
        "effect_name" => effect_name,
        "header" => header,
        "informed_entity" => informed_entities,
        "severity" => severity
      },
      "id" => alert_id
    }, facilities_map, accumulator
  ) when is_binary(header) do
    Map.put(
      accumulator,
      alert_id,
      struct(Alert, %{
        id: alert_id,
        active_period: parse_active_periods(active_periods),
        effect_name: effect_name,
        header: header,
        informed_entities: parse_informed_entities(informed_entities, facilities_map),
        severity: severity |> String.downcase |> String.to_existing_atom
      })
    )
  end

  defp parse_alert(_, _, accumulator) do
    accumulator
  end

  defp parse_active_periods(active_periods) do
    Enum.map(active_periods, &parse_active_period(&1))
  end

  defp parse_active_period(active_period) do
    Map.new(active_period, fn({k, v}) ->
      with {:ok, datetime, _} <- DateTime.from_iso8601(v) do
        {String.to_existing_atom(k), datetime}
      else
        _ -> {String.to_existing_atom(k), nil}
      end
    end)
  end

  defp parse_informed_entities(informed_entities, facilities_map) do
    Enum.map(informed_entities, fn(ie) ->
      informed_entity = Map.new(ie, fn({k, v}) -> {String.to_existing_atom(k), v} end)
      with %{"facility" => facility_id} <- ie,
           %{^facility_id => facility_type} <- facilities_map
      do
        Map.put(informed_entity, :facility_type, facility_type |> String.downcase |> String.to_existing_atom)
      else
        _ -> informed_entity
      end
    end)
  end
end
