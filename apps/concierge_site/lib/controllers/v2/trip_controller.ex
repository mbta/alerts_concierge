defmodule ConciergeSite.V2.TripController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.Trip

  action_fallback ConciergeSite.V2.FallbackController

  def index(conn, _params, user, _claims) do
    trips = Trip.get_trips_by_user(user.id)
    render conn, "index.html", trips: trips
  end

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def create(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def edit(conn, %{"id" => id}, user, _claims) do
    with {:trip, %Trip{} = trip} <- {:trip, Trip.find_by_id(id)},
         {:authorized, true} <- {:authorized, user.id == trip.user_id} do
      render(conn, "edit.html", trip: trip)
    else
      {:trip, nil} ->
        {:error, :not_found}
      {:authorized, false} ->
        {:error, :not_found}
    end
  end

  def update(conn, %{"id" => id}, _user, _claims) do
    render conn, "edit.html", trip: Trip.find_by_id(id)
  end

  def leg(conn, %{"trip" => trip}, _user, _claims) do
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
    "destinations" => destinations, "round_trip" => round_trip}}, _user, _claims) do
    render conn, "times.html", legs: legs, origins: origins, destinations: destinations,
      round_trip: round_trip
  end

  def accessibility(conn, _params, _user, _claims) do
    render conn, "accessibility.html"
  end

  def delete(conn, %{"id" => id}, user, _claims) do
    with %Trip{} = trip <- Trip.find_by_id(id),
         true <- user.id == trip.user_id,
         {:ok, %Trip{}} <- Trip.delete(trip) do
      redirect(conn, to: v2_trip_path(conn, :index))
    else
      _ ->
        {:error, :not_found}
    end
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
