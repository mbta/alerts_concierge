defmodule ConciergeSite.V2.TripController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, _params) do
    render conn, "new.html"
  end

  def edit(conn, _params) do
    render conn, "edit.html"
  end

  def update(conn, _params) do
    render conn, "edit.html"
  end

  def leg(conn, %{"trip" => trip}) do
    case trip do
      %{"route" => route, "saved_leg" => saved_leg, "origin" => origin,
        "destination" => destination, "round_trip" => round_trip, "new_leg" => "true"} ->

        [leg, route_name, mode] = String.split(route, "~~")
        {legs, origins, destinations} = parse_legs(trip, saved_leg, origin, destination)
        conn = %{conn | params: %{}}

        render conn, "leg.html", legs: legs, origins: origins, destinations: destinations,
          round_trip: round_trip, route_name: route_name, mode: mode, saved_leg: leg
      %{"saved_leg" => saved_leg, "origin" => origin, "destination" => destination,
        "round_trip" => round_trip, "new_leg" => "false"} ->

        {legs, origins, destinations} = parse_legs(trip, saved_leg, origin, destination)
        conn = %{conn | params: %{}}

        render conn, "times.html", legs: legs, origins: origins, destinations: destinations,
          round_trip: round_trip
      %{"route" => route, "round_trip" => round_trip, "from_new_trip" => "true"} ->

        [leg, route_name, mode] = String.split(route, "~~")
        conn = %{conn | params: %{}}

        render conn, "leg.html", legs: [], origins: [], destinations: [],
          round_trip: round_trip, route_name: route_name, mode: mode, saved_leg: leg
      _ ->
        conn = put_flash(conn, :error, "There was an error creating your trip. Please try again.")
        render conn, "new.html"
    end
  end

  def times(conn, %{"trip" => %{"legs" => legs, "origins" => origins,
    "destinations" => destinations, "round_trip" => round_trip}}) do
    render conn, "times.html", legs: legs, origins: origins, destinations: destinations,
      round_trip: round_trip
  end

  def accessibility(conn, _params) do
    render conn, "accessibility.html"
  end

  def delete(conn, _params) do
    redirect(conn, to: v2_trip_path(conn, :index))
  end

  defp leg_list(%{"legs" => legs}), do: legs
  defp leg_list(_), do: []

  defp origin_list(%{"origins" => origins}), do: origins
  defp origin_list(_), do: []

  defp destination_list(%{"destinations" => destinations}), do: destinations
  defp destination_list(_), do: []

  defp parse_legs(trip, saved_leg, origin, destination) do
    legs = leg_list(trip)
    origins = origin_list(trip)
    destinations = destination_list(trip)

    legs = [saved_leg | legs]
    origins = [origin | origins]
    destinations = [destination | destinations]

    {legs, origins, destinations}
  end
end
