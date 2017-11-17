defmodule AlertProcessor.AlertsClient do
  @moduledoc """
  HTTPoison wrapper for alerts enhanced json feed
  """
  use HTTPoison.Base
  alias AlertProcessor.Helpers.ConfigHelper

  @doc """
  fetch all alerts from enhanced json feed
  """
  @spec get_alerts() :: [map] | {:ok, map, integer} | {:error, String.t}
  def get_alerts do
    case get(alerts_url()) do
      {:ok, %{body: %{"alerts" => alerts, "timestamp" => timestamp}}} ->
        {:ok, alerts, timestamp}
      {:ok, %{body: %{"header" => %{"timestamp" => timestamp}, "entity" => entity}}} ->
        reconstructed_alerts = Enum.map(entity, &alert_from_entity/1)
        {:ok, reconstructed_alerts, timestamp}
      {:error, message} ->
        {:error, message}
    end
  end

  defp alerts_url do
    ConfigHelper.get_string(:alert_api_url)
  end

  defp process_response_body(body) do
    Poison.decode!(body)
  end

  defp alert_from_entity(%{"id" => id, "alert" => alert}) do
    alert
    |> Map.put("id", id)
  end
end
