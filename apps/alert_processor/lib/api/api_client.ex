defmodule AlertProcessor.ApiClient do
  @moduledoc """
  HTTPoison wrapper for MBTA API
  """
  require Logger

  use HTTPoison.Base

  alias AlertProcessor.Model.{Route, TripInfo}
  alias AlertProcessor.Helpers.ConfigHelper

  @doc """
  Helper function that fetches all alerts from
  MBTA Alerts API
  """
  @spec get_alerts() :: {:ok, [map], [map]} | {:error, String.t()}
  def get_alerts do
    Logger.info(fn ->
      "Fetching alerts from the MBTA Alerts API"
    end)

    case api_get("/alerts", include: "facilities") do
      {:ok, %{body: %{"errors" => errors}}} ->
        formatted_errors = errors |> Enum.map_join(", ", & &1["code"])

        Logger.error(fn ->
          "Error retrieving alerts: #{formatted_errors}"
        end)

        {:error, formatted_errors}

      {:ok, %{body: %{"included" => facilities, "data" => alerts}}} ->
        Logger.info(fn ->
          "Alerts successfully retrieved from the MBTA Alerts API"
        end)

        {:ok, alerts, facilities}

      {:ok, %{body: %{"data" => alerts}}} ->
        Logger.info(fn ->
          "Alerts successfully retrieved from the MBTA Alerts API"
        end)

        {:ok, alerts, []}

      {:error, message} ->
        Logger.error(fn ->
          "Error fetching alerts: #{message}"
        end)

        {:error, message}
    end
  end

  @doc """
  endpoint to fetch facility information to match facility id with facility_type
  """
  @spec facilities() :: {:ok, [map]} | {:error, String.t()}
  def facilities do
    "/facilities"
    |> api_get()
    |> parse_response()
  end

  @doc """
  enpoint to fetch route info including name, id and route_type
  """
  @spec routes([integer], [String.t()]) :: {:ok, [map]} | {:error, String.t()}
  def routes(
        types \\ [],
        fields \\ ["long_name", "type", "direction_names", "short_name", "direction_destinations"]
      ) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/routes"
    |> api_get("filter[type]": Enum.join(types, ","), "fields[route]": Enum.join(fields, ","))
    |> parse_response()
  end

  @doc """
  endpoint to fetch trips for a specific route
  """
  @spec trips(String.t(), integer, [String.t()]) :: {:ok, [map]} | {:error, String.t()}
  def trips(route, direction_id, fields \\ ["headsign"]) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/trips"
    |> api_get(route: route, direction_id: direction_id, "fields[trip]": Enum.join(fields, ","))
    |> parse_response()
  end

  @doc """
  endpoint to fetch trips for a set of routes and include service information
  """
  @spec trips_with_service_info([String.t()]) :: {:ok, [map], [map]} | {:error, String.t()}
  def trips_with_service_info(routes) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/trips"
    |> api_get(route: Enum.join(routes, ","), include: "service")
    |> parse_response()
  end

  @doc """
  endpoint to fetch stop info per route including name and id for the inbound direction only
  """
  @spec route_stops(String.t()) :: {:ok, [map]} | {:error, String.t()}
  def route_stops(route) do
    "/stops"
    |> api_get(route: route, direction_id: "1")
    |> parse_response()
  end

  @doc """
  endpoint to fetch stops which includes parent station id
  """
  @spec parent_stations() :: {:ok, [map]} | {:error, String.t()}
  def parent_stations do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/stops"
    |> api_get()
    |> parse_response()
  end

  @doc """
  endpoint to fetch shapes for a specific route
  """
  @spec route_shapes(String.t()) :: {:ok, [map]} | {:error, String.t()}
  def route_shapes(route) do
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/shapes"
    |> api_get(route: route, direction_id: "1", "fields[shape]": "priority")
    |> parse_response()
  end

  @doc """
  endpoint to fetch schedules for two stops to be able to find common schedules
  """
  @spec schedules(
          Route.stop_id(),
          Route.stop_id(),
          Route.direction_id() | nil,
          [Route.route_id()],
          Date.t() | nil
        ) :: {:ok, [map], [map]} | {:ok, [map]} | {:error, String.t()}
  def schedules(origin, destination, direction_id, route_ids, date) do
    sorted_stations = Enum.sort_by([origin, destination], &String.downcase/1)
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/schedules"
    |> api_get(
      "filter[stop]": Enum.join(sorted_stations, ","),
      direction_id: direction_id,
      "fields[schedule]": "departure_time,arrival_time",
      "filter[route]": Enum.join(route_ids, ","),
      date: date,
      include: "trip,stop",
      "fields[trip]": "name"
    )
    |> parse_response()
  end

  @spec schedules_for_stops([Route.stop_id()], Date.t()) ::
          {:ok, [map], [map]} | {:ok, [map]} | {:error, String.t()}
  def schedules_for_stops(stations, date) when is_list(stations) do
    sorted_stations = Enum.sort_by(stations, &String.downcase/1)
    # credo:disable-for-next-line Credo.Check.Readability.SpaceAfterCommas
    "/schedules"
    |> URI.encode()
    |> api_get(
      "filter[stop]": Enum.join(sorted_stations, ","),
      "fields[schedule]": "departure_time,arrival_time",
      date: date,
      include: "trip",
      "fields[trip]": "name"
    )
    |> parse_response()
  end

  @spec schedule_for_trip(TripInfo.id()) :: {:ok, [map]} | {:error, String.t()}
  def schedule_for_trip(trip_id) do
    "/schedules"
    |> api_get(trip: trip_id)
    |> parse_response()
  end

  @doc """
  endpoint to fetch schedules for two subway stops to be able to determine if stops have trips in common
  """
  @spec subway_schedules_union(String.t(), String.t()) :: {:ok, map, map} | {:error, String.t()}
  def subway_schedules_union(origin, destination) do
    # credo:disable-for-lines:3 Credo.Check.Readability.SpaceAfterCommas
    routes = "Red,Blue,Orange,Green-B,Green-C,Green-D,Green-E,Mattapan"

    response =
      "/schedules"
      |> api_get(
        "filter[route]": routes,
        "filter[stop]": "#{origin},#{destination}",
        "fields[stop]": "parent_station",
        "fields[schedule]": "",
        include: "stop"
      )

    case response do
      {:ok, %{body: %{"data" => schedules, "included" => included}}} ->
        Logger.info(fn ->
          "Schedules successfully retrieved"
        end)

        {:ok, schedules, included}

      {:error, message} ->
        Logger.error(fn ->
          "Error in request to '/schedules': #{message}"
        end)

        {:error, message}
    end
  end

  defp parse_response(response) do
    case response do
      {:ok, %{body: %{"errors" => errors}}} ->
        formatted_errors = errors |> Enum.map_join(", ", & &1["code"])

        Logger.error(fn ->
          "Error retrieving alerts: #{formatted_errors}"
        end)

        {:error, formatted_errors}

      {:ok, %{body: %{"data" => data, "included" => includes}}} ->
        Logger.info(fn ->
          "Response successfully parsed"
        end)

        {:ok, data, includes}

      {:ok, %{body: %{"data" => data}}} ->
        Logger.info(fn ->
          "Response successfully parsed"
        end)

        {:ok, data}

      {:error, message} ->
        Logger.error(fn ->
          "Error parsing the response: #{message}"
        end)

        {:error, message}
    end
  end

  defp process_url(url) do
    :api_url
    |> ConfigHelper.get_string()
    |> URI.merge(url)
    |> URI.to_string()
  end

  defp process_response_body(body) do
    Poison.decode!(body)
  end

  defp api_get(path, params \\ []) do
    get(path, add_api_key([]), params: params, timeout: 30_000, recv_timeout: 30_000)
  end

  defp add_api_key(headers) do
    case ConfigHelper.get_string(:api_key) do
      nil -> headers
      key -> Keyword.put(headers, :"x-api-key", key)
    end
  end
end
