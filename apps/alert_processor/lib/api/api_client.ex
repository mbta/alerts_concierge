defmodule AlertProcessor.ApiClient do
  @moduledoc """
  HTTPoison wrapper for MBTA API
  """
  use HTTPoison.Base

  @doc """
  Helper function that fetches all alerts from
  MBTA Alerts API
  """
  @spec get_alerts() :: [map] | {atom, map}
  def get_alerts do
   case get("/alerts/?include=facilities") do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"included" => facilities, "data" => alerts}}} ->
        {alerts, facilities}
      {:ok, %{body: %{"data" => alerts}}} ->
        {alerts, []}
      {:error, message} ->
        {:error, message}
    end
  end

  @spec routes([String.t], [String.t]) :: {:ok, [map]} | {:error, String.t}
  def routes(types \\ [], fields \\ ["long_name", "type"]) do
    case get("/routes?filter[type]=#{Enum.join(types, ",")}&fields[route]=#{Enum.join(fields, ",")}") do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"data" => routes}}} ->
        routes
      {:error, message} ->
        {:error, message}
    end
  end

  @spec route_stops(String.t) :: {:ok, [map]} | {:error, String.t}
  def route_stops(route) do
    case get("/stops/?route=#{route}&direction_id=1") do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"data" => stops}}} ->
        stops
      {:error, message} ->
        {:error, message}
    end
  end

  defp process_url(url) do
    "API_URL" |> System.get_env |> URI.merge(url) |> URI.to_string
  end

  defp process_response_body(body) do
    Poison.decode!(body)
  end
end
