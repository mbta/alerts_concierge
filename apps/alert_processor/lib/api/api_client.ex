defmodule AlertProcessor.ApiClient do
  @moduledoc """
  HTTPoison wrapper for MBTA API
  """
  use HTTPoison.Base

  @doc """
  Helper function that fetches all alerts from
  MBTA Alerts API
  """
  @spec get_alerts() :: {[map], [map]} | {:error, String.t}
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
  endpoint to fetch facility information to match facility id with facility_type
  """
  @spec facilities() :: [map] | {:error, String.t}
  def facilities do
    "/facilities?fields[facility]=type"
    |> get()
    |> parse_response()
  end

  @doc """
  enpoint to fetch route info including name, id and route_type
  """
  @spec routes([integer], [String.t]) :: [map] | {:error, String.t}
  def routes(types \\ [], fields \\ ["long_name", "type", "direction_names"]) do
    "/routes?filter[type]=#{Enum.join(types, ",")}&fields[route]=#{Enum.join(fields, ",")}"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch trips for a specific route
  """
  @spec trips(String.t, integer, [String.t]) :: [map] | {:error, String.t}
  def trips(route, direction_id, fields \\ ["headsign"]) do
    "/trips?route=#{route}&direction_id=#{direction_id}&fields[trip]=#{Enum.join(fields, ",")}"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch stop info per route including name and id
  """
  @spec route_stops(String.t) :: [map] | {:error, String.t}
  def route_stops(route) do
    "/stops/?route=#{route}&direction_id=1"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch subway stops which includes parent station id
  """
  @spec subway_parent_stops() :: [map] | {:error, String.t}
  def subway_parent_stops do
    "/stops?filter[route_type]=0,1"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch shapes for a specific route
  """
  @spec route_shapes(String.t) :: [map] | {:error, String.t}
  def route_shapes(route) do
    "/shapes/?route=#{route}&direction_id=1&fields[shape]=priority"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch schedules for two stops to be able to find common schedules
  """
  @spec schedules(String.t, String.t, integer, [String.t], Date.t) :: [map] | {:error, String.t}
  def schedules(origin, destination, direction_id, route_ids, date) do
    "/schedules?filter[stop]=#{origin},#{destination}&direction_id=#{direction_id}&fields[schedule]=departure_time,arrival_time&filter[route]=#{Enum.join(route_ids, ",")}&date=#{date}"
    |> URI.encode()
    |> get()
    |> parse_response()
  end

  defp parse_response(response) do
    case response do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"data" => data}}} ->
        data
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
