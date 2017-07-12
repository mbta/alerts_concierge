defmodule AlertProcessor.ApiClient do
  @moduledoc """
  HTTPoison wrapper for MBTA API
  """
  use HTTPoison.Base

  alias AlertProcessor.Model.Route

  @doc """
  Helper function that fetches all alerts from
  MBTA Alerts API
  """
  @spec get_alerts() :: {:ok, [map], [map]} | {:error, String.t}
  def get_alerts do
   case get("/alerts/?include=facilities") do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"included" => facilities, "data" => alerts}}} ->
        {:ok, alerts, facilities}
      {:ok, %{body: %{"data" => alerts}}} ->
        {:ok, alerts, []}
      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  endpoint to fetch facility information to match facility id with facility_type
  """
  @spec facilities() :: {:ok, [map]} | {:error, String.t}
  def facilities do
    "/facilities?fields[facility]=type"
    |> get()
    |> parse_response()
  end

  @doc """
  enpoint to fetch route info including name, id and route_type
  """
  @spec routes([integer], [String.t]) :: {:ok, [map]} | {:error, String.t}
  def routes(types \\ [], fields \\ ["long_name", "type", "direction_names"]) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/routes?filter[type]=#{Enum.join(types, ",")}&fields[route]=#{Enum.join(fields, ",")}"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch trips for a specific route
  """
  @spec trips(String.t, integer, [String.t]) :: {:ok, [map]} | {:error, String.t}
  def trips(route, direction_id, fields \\ ["headsign"]) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/trips?route=#{route}&direction_id=#{direction_id}&fields[trip]=#{Enum.join(fields, ",")}"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch stop info per route including name and id
  """
  @spec route_stops(String.t) :: {:ok, [map]} | {:error, String.t}
  def route_stops(route) do
    "/stops/?route=#{route}&direction_id=1"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch subway stops which includes parent station id
  """
  @spec subway_parent_stops() :: {:ok, [map]} | {:error, String.t}
  def subway_parent_stops do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/stops?filter[route_type]=0,1"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch shapes for a specific route
  """
  @spec route_shapes(String.t) :: {:ok, [map]} | {:error, String.t}
  def route_shapes(route) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/shapes/?route=#{route}&direction_id=1&fields[shape]=priority"
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch schedules for two stops to be able to find common schedules
  """
  @spec schedules(Route.stop_id, Route.stop_id, Route.direction_id | nil, [Route.route_id], Date.t | nil) :: {:ok, [map], [map]} | {:ok, [map]} | {:error, String.t}
  def schedules(origin, destination, direction_id, route_ids, date) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/schedules?filter[stop]=#{origin},#{destination}&direction_id=#{direction_id}&fields[schedule]=departure_time,arrival_time&filter[route]=#{Enum.join(route_ids, ",")}&date=#{date}&include=trip,stop&fields[trip]=name"
    |> URI.encode()
    |> get()
    |> parse_response()
  end
  def schedules(stations, date) when is_list(stations) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/schedules?filter[stop]=#{Enum.join(stations, ",")}&fields[schedule]=departure_time,arrival_time&date=#{date}&include=trip&fields[trip]=name"
    |> URI.encode()
    |> get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch schedules for two subway stops to be able to determine if stops have trips in common
  """
  @spec subway_schedules_union(String.t, String.t) :: {:ok, map, map} | {:error, String.t}
  def subway_schedules_union(origin, destination) do
    # credo:disable-for-lines:3 Credo.Check.Readability.SpaceAfterCommas
    routes = "Red,Blue,Orange,Green-B,Green-C,Green-D,Green-E"
    response = get(
      "/schedules/?filter[route]=#{routes}&filter[stop]=#{origin},#{destination}&fields[stop]=parent_station&fields[schedule]=&include=stop"
    )
    case response do
      {:ok, %{body: %{"data" => schedules, "included" => included}}} ->
        {:ok, schedules, included}
      {:error, message} ->
        {:error, message}
    end
  end

  defp parse_response(response) do
    case response do
      {:ok, %{body: %{"errors" => errors}}} ->
        {:error, errors |> Enum.map_join(", ", &(&1["code"]))}
      {:ok, %{body: %{"data" => data, "included" => includes}}} ->
        {:ok, data, includes}
      {:ok, %{body: %{"data" => data}}} ->
        {:ok, data}
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
