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

  @doc """
  enpoint to fetch route info including name, id and route_type
  """
  @spec routes([integer], [String.t]) :: {:ok, [map]} | {:error, String.t}
  def routes(types \\ [], fields \\ ["long_name", "type", "direction_names"]) do
    case get("/routes?filter[type]=#{Enum.join(types, ",")}&fields[route]=#{Enum.join(fields, ",")}") do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"data" => routes}}} ->
        routes
      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  endpoint to fetch trips for a specific route
  """
  def trips(route, direction_id, fields \\ ["headsign"]) do
    case get("/trips?route=#{route}&direction_id=#{direction_id}&fields[trip]=#{Enum.join(fields, ",")}") do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"data" => trips}}} ->
        trips
      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  endpoint to fetch stop info per route including name and id
  """
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

  @doc """
  endpoint to fetch shapes for a specific route
  """
  def route_shapes(route) do
    case get("/shapes/?route=#{route}&direction_id=1&fields[shape]=priority") do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"data" => shapes}}} ->
        shapes
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
