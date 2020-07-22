defmodule AlertProcessor.AlertsClient do
  @moduledoc """
  HTTPoison wrapper for alerts enhanced json feed
  """
  use HTTPoison.Base
  alias AlertProcessor.Helpers.ConfigHelper
  require Logger

  @doc """
  fetch all alerts from enhanced json feed
  """
  @spec get_alerts() :: [map] | {:ok, map, integer} | {:error, String.t()}
  def get_alerts do
    case get(alerts_url()) do
      {:ok, %{body: {:ok, %{"alerts" => alerts, "timestamp" => timestamp}}}} ->
        {:ok, alerts, timestamp}

      {:ok, %{body: {:ok, %{"header" => %{"timestamp" => timestamp}, "entity" => entity}}}} ->
        reconstructed_alerts = Enum.map(entity, &alert_from_entity/1)
        {:ok, reconstructed_alerts, timestamp}

      {:ok, %{body: {:error, reason}}} ->
        Logger.warn(fn -> "Error getting alerts enhanced JSON: reason=#{inspect(reason)}" end)
        {:ok, [], nil}

      {:error, message} ->
        Logger.warn(fn -> "Error getting alerts: #{message}" end)
        {:error, message}
    end
  end

  defp alerts_url do
    ConfigHelper.get_string(:alert_api_url)
  end

  defp process_response_body(body) do
    Poison.decode(body)
  end

  defp alert_from_entity(%{"id" => id, "alert" => alert}) do
    alert
    |> Map.put("id", id)
  end
end
