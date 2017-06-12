defmodule AlertProcessor.AlertsClient do
  @moduledoc """
  HTTPoison wrapper for alerts enhanced json feed
  """
  use HTTPoison.Base
  alias AlertProcessor.Helpers.ConfigHelper

  @doc """
  fetch all alerts from enhanced json feed
  """
  @spec get_alerts() :: [map] | {atom, map}
  def get_alerts do
   case get("alerts_enhanced.json") do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"alerts" => alerts}}} ->
        {:ok, alerts}
      {:error, message} ->
        {:error, message}
    end
  end

  defp process_url(url) do
    :alert_api_url |> ConfigHelper.get_string() |> URI.merge(url) |> URI.to_string
  end

  defp process_response_body(body) do
    Poison.decode!(body)
  end
end
