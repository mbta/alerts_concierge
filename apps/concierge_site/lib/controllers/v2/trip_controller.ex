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
         {:authorized, true} <- {:authorized, user.id == trip.user_id},
         {:changeset, changeset} <- {:changeset, Trip.update_changeset(trip)} do
      render(conn, "edit.html", trip: trip, changeset: changeset)
    else
      {:trip, nil} ->
        {:error, :not_found}
      {:authorized, false} ->
        {:error, :not_found}
    end
  end

  def update(conn, %{"id" => id, "trip" => trip_params}, user, _claims) do
    with {:trip, %Trip{} = trip} <- {:trip, Trip.find_by_id(id)},
         {:authorized, true} <- {:authorized, user.id == trip.user_id},
         {:sanitized, sanitized_trip_params} <- {:sanitized, sanitize_trip_params(trip_params)},
         {:ok, %Trip{} = updated_trip} <- Trip.update(trip, sanitized_trip_params) do
      conn
      |> put_flash(:info, "Trip updated.")
      |> render("edit.html", trip: updated_trip, changeset: Trip.update_changeset(updated_trip))
    else
      {:trip, nil} ->
        {:error, :not_found}
      {:authorized, false} ->
        {:error, :not_found}
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Trip could not be updated. Please see errors below.")
        |> render("edit.html", trip: Trip.find_by_id(id), changeset: changeset)
    end
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

  defp sanitize_trip_params(trip_params) when is_map(trip_params) do
    trip_params
    |> Enum.map(&sanitize_trip_param/1)
    |> Enum.into(%{})
  end

  defp sanitize_trip_param({"relevant_days" = key, relevant_days}) do
    days_as_atoms = Enum.map(relevant_days, &String.to_existing_atom/1)
    {key, days_as_atoms}
  end

  defp sanitize_trip_param({"alert_time_difference_in_minutes" = key, minutes}) do
    {key, minutes}
  end

  @valid_time_keys ~w(start_time end_time return_start_time return_end_time alert_time)

  defp sanitize_trip_param({time_key, time_value}) when time_key in @valid_time_keys do
    time =
      case String.split(time_value, ":") do
        [hours, minutes] -> "#{hours}:#{minutes}:00"
        [_hours, _minutes, _seconds] -> time_value
      end
    {time_key, Time.from_iso8601!(time)}
  end
end
