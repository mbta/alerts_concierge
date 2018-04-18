defmodule ConciergeSite.V2.TripController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.ApiClient
  alias AlertProcessor.Model.{Trip, Subscription, User, TripInfo}
  alias AlertProcessor.ServiceInfoCache
  alias Ecto.Multi

  plug :scrub_params, "trip" when action in [:create, :leg]

  action_fallback ConciergeSite.V2.FallbackController

  def index(conn, _params, user, _claims) do
    trips = Trip.get_trips_by_user(user.id)
    render conn, "index.html", trips: trips, user_id: user.id
  end

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def create(conn, %{"trip" => trip_params}, user, {:ok, claims}) do
    params = parse_input(trip_params)
    subscriptions = input_to_subscriptions(user, params)
    trip = input_to_trip(user, params)
    multi = build_trip_transaction(trip, subscriptions, user, Map.get(claims, "imp", user.id))
    case Subscription.set_versioned_subscription(multi) do
      :ok ->
        conn
        |> put_flash(:info, "Success! If at any time you need to edit the features, stations, or lines you've subscribed to, you can click in the box below.")
        |> redirect(to: v2_trip_path(conn, :index))
      :error ->
        conn
        |> put_flash(:error, "There was an error creating your trip. Please try again.")
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}, user, _claims) do
    with {:trip, %Trip{} = trip} <- {:trip, Trip.find_by_id(id)},
         {:authorized, true} <- {:authorized, user.id == trip.user_id},
         {:changeset, changeset} <- {:changeset, Trip.update_changeset(trip)} do

      schedules = get_schedules_for_trip(trip.subscriptions, false)
      return_schedules = get_schedules_for_trip(trip.subscriptions, true)
      render(conn, "edit.html", trip: trip, changeset: changeset, schedules: schedules,
                                return_schedules: return_schedules)
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
         {:ok, %Trip{}} <- Trip.update(trip, sanitized_trip_params) do
      conn
      |> put_flash(:info, "Trip updated.")
      |> redirect(to: v2_trip_path(conn, :index))
    else
      {:trip, nil} ->
        {:error, :not_found}
      {:authorized, false} ->
        {:error, :not_found}
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Trip could not be updated. Please see errors below.")
        |> render("edit.html", trip: Trip.find_by_id(id), changeset: changeset, schedules: %{}, return_schedules: %{})
    end
  end

  def leg(conn, %{"trip" => %{"origin" => origin, "destination" => destination}}, _, _)
      when not is_nil(origin) and origin == destination do
    conn
    |> put_flash(:error, "There was an error. Trip origin and destination must be different.")
    |> render("new.html")
  end

  def leg(conn, %{"trip" => trip}, _user, _claims) do
    case trip do
      %{"route" => route, "saved_leg" => saved_leg, "origin" => origin,
        "destination" => destination, "round_trip" => round_trip, "new_leg" => "true",
        "saved_mode" => saved_mode} ->

        [leg, route_name, mode] = String.split(route, "~~")
        {legs, origins, destinations, modes} = parse_legs(trip, saved_leg, origin, destination, saved_mode)
        conn = %{conn | params: %{}}

        render conn, "leg.html", legs: legs, origins: origins, destinations: destinations,
          round_trip: round_trip, route_name: route_name, mode: mode, saved_leg: leg, saved_mode: mode,
          modes: modes
      %{"saved_leg" => saved_leg, "origin" => origin, "destination" => destination,
        "round_trip" => round_trip, "new_leg" => "false", "saved_mode" => saved_mode} ->
        {legs, origins, destinations, modes} = parse_legs(trip, saved_leg, origin, destination, saved_mode)
        conn = %{conn | params: %{}}
        schedules = get_schedules_for_input(legs, origins, destinations, modes)
        return_schedules = get_schedules_for_input(legs, destinations, origins, modes)

        render conn, "times.html", legs: legs, origins: origins, destinations: destinations, round_trip: round_trip,
                                   modes: modes, schedules: schedules, return_schedules: return_schedules
      %{"route" => route, "round_trip" => round_trip, "from_new_trip" => "true"} ->

        [leg, route_name, mode] = String.split(route, "~~")
        conn = %{conn | params: %{}}

        render conn, "leg.html", legs: [], origins: [], destinations: [], round_trip: round_trip,
          route_name: route_name, saved_mode: mode, saved_leg: leg, modes: []
      _ ->
        conn = put_flash(conn, :error, "There was an error creating your trip. Please try again.")
        render conn, "new.html"
    end
  end

  def times(conn, %{"trip" => %{"legs" => legs, "origins" => origins,
    "destinations" => destinations, "modes" => modes, "round_trip" => round_trip}},
    _user, _claims) do

    schedules = get_schedules_for_input(legs, origins, destinations, modes)
    return_schedules = get_schedules_for_input(legs, destinations, origins, modes)

    render conn, "times.html", legs: legs, origins: origins, destinations: destinations,
      modes: modes, round_trip: round_trip, schedules: schedules, return_schedules: return_schedules
  end

  def delete(conn, %{"id" => id}, user, _claims) do
    with %Trip{} = trip <- Trip.find_by_id(id),
         true <- user.id == trip.user_id,
         {:ok, %Trip{}} <- Trip.delete(trip) do
      conn
      |> put_flash(:info, "Alert deleted.")
      |> redirect(to: v2_trip_path(conn, :index))
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

  defp mode_list(%{"modes" => modes}), do: modes
  defp mode_list(_), do: []

  defp parse_legs(trip, saved_leg, origin, destination, saved_mode) do
    legs = leg_list(trip)
    origins = origin_list(trip)
    destinations = destination_list(trip)
    modes = mode_list(trip)

    legs = [saved_leg | legs]
    origins = [origin | origins]
    destinations = [destination | destinations]
    modes = [saved_mode | modes]

    {legs, origins, destinations, modes}
  end

  defp to_time(nil), do: nil
  defp to_time(form_time) do
    [hour, minute] = Enum.map(String.split(form_time, ":"), &String.to_integer/1)
    {:ok, time} = Time.new(hour, minute, 0)

    time
  end

  defp build_trip_transaction(trip, subscriptions, user, originator) do
    trip_id = Ecto.UUID.generate
    trip = Map.put(trip, :id, trip_id)

    multi = Multi.run(Multi.new, {:trip, 0}, fn _ ->
      PaperTrail.insert(trip, originator: User.wrap_id(originator), meta: %{owner: user.id})
    end)

    subscriptions
    |> Enum.with_index
    |> Enum.reduce(multi, fn({sub, index}, acc) ->
      sub_to_insert = sub
      |> Map.merge(%{id: Ecto.UUID.generate, user_id: user.id, trip_id: trip.id, facility_types: trip.facility_types})
      |> Subscription.create_changeset()

      acc
      |> Multi.run({:subscription, index}, fn _ ->
           PaperTrail.insert(sub_to_insert, originator: User.wrap_id(originator), meta: %{owner: user.id})
         end)
    end)
  end

  defp parse_input(params) do
    params
    |> Map.put("relevant_days", Map.get(params, "relevant_days", []))
    |> Map.put("start_time", to_time(params["start_time"]))
    |> Map.put("end_time", to_time(params["end_time"]))
    |> Map.put("return_start_time", to_time(params["return_start_time"]))
    |> Map.put("return_end_time", to_time(params["return_end_time"]))
  end

  defp input_to_subscriptions(user, params) do
    Enum.zip([Enum.reverse(params["modes"]), Enum.reverse(params["legs"]), Enum.reverse(params["origins"]),
              Enum.reverse(params["destinations"]), Stream.iterate(0, &(&1+1))])
    |> Enum.flat_map(fn {type, route_in, origin, destination, rank} ->
      {route_id, direction} = determine_route(route_in)
      {:ok, route} = ServiceInfoCache.get_route(route_id)
      %Subscription{
        alert_priority_type: "low",
        user_id: user.id,
        relevant_days: Enum.map(params["relevant_days"], &String.to_existing_atom/1),
        start_time: params["start_time"],
        end_time: params["end_time"],
        origin: origin,
        destination: destination,
        type: type,
        route: route_id,
        route_type: route.route_type,
        direction_id: determine_direction_id(route.stop_list, direction, origin, destination),
        rank: rank,
        return_trip: false}
      |> Subscription.add_latlong_to_subscription(origin, destination)
      |> add_return_subscription(params)
    end)
  end

  defp add_return_subscription(subscription, %{"round_trip" => "true", "return_start_time" => return_start_time,
                                               "return_end_time" => return_end_time}) do
    return_subscription = %{
      subscription | start_time: return_start_time, end_time: return_end_time, origin: subscription.destination,
                     origin_lat: subscription.destination_lat, origin_long: subscription.destination_long,
                     destination: subscription.origin, destination_lat: subscription.origin_lat,
                     destination_long: subscription.origin_long, direction_id: flip_direction(subscription.direction_id),
                     return_trip: true}
    [subscription, return_subscription]
  end
  defp add_return_subscription(subscription, _), do: [subscription]

  defp input_to_trip(user, params) do
    %Trip{
      user_id: user.id,
      alert_priority_type: "low",
      relevant_days: Enum.map(params["relevant_days"], &String.to_existing_atom/1),
      start_time: params["start_time"],
      end_time: params["end_time"],
      return_start_time: params["return_start_time"],
      return_end_time: params["return_end_time"],
      facility_types: input_to_facility_types(params),
      roundtrip: params["round_trip"] == "true"
    }
  end

  defp input_to_facility_types(params) do
    ["bike_storage", "elevator", "escalator", "parking_area"]
    |> Enum.reduce([], fn(type, acc) ->
      if params[type] == "true" do
        acc ++ [String.to_atom(type)]
      else
        acc
      end
    end)
  end

  defp flip_direction(0), do: 1
  defp flip_direction(1), do: 0

  defp determine_direction_id(_, "0", _, _), do: 0
  defp determine_direction_id(_, "1", _, _), do: 1
  defp determine_direction_id(stop_list, _, origin, destination) do
    case stop_list
      |> Enum.filter(fn({_name, id, _latlong, _wheelchair}) -> Enum.member?([origin, destination], id) end)
      |> Enum.map(fn({_name, id, _latlong, _wheelchair}) -> id end) do
        [^origin, ^destination] -> 1
        [^destination, ^origin] -> 0
    end
  end

  defp determine_route(route_id) do
    route_id
    |> String.split(" - ")
    |> Enum.reduce({}, fn(part, acc) ->
      if acc == {} do
        {part, nil}
      else
        {elem(acc, 0), part}
      end
    end)
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

  defp get_schedules_for_input(legs, origins, destinations, modes) do
    Enum.zip([Enum.reverse(modes), Enum.reverse(legs), Enum.reverse(origins), Enum.reverse(destinations)])
    |> Enum.reduce(%{}, fn({mode, route, origin, destination}, acc) ->
      case mode do
        "subway" -> acc
        "bus" -> acc
        _ -> Map.put(acc, {mode, route}, get_schedule(route, origin, destination))
      end
    end)
  end

  defp get_schedules_for_trip(subscriptions, return_trip) do
    subscriptions
    |> Enum.filter(& &1.return_trip == return_trip)
    |> Enum.reduce(%{}, fn(%{type: type, route: route, origin: origin, destination: destination}, acc) ->
      case type do
        :subway -> acc
        :bus -> acc
        _ -> Map.put(acc, {Atom.to_string(type), route}, get_schedule(route, origin, destination))
      end
    end)
  end

  defp get_schedule(route_id, origin, destination) do
    with {:ok, route} <- ServiceInfoCache.get_route(route_id) do
      direction_id = determine_direction_id(route.stop_list, nil, origin, destination)
      {:ok, schedules, trips} = ApiClient.schedules(origin, destination, direction_id, [route.route_id],
                                                    Calendar.Date.today!("America/New_York"))
      trip_name_map = map_trip_names(trips)
      {:ok, origin_stop} = ServiceInfoCache.get_stop(origin)
      {:ok, destination_stop} = ServiceInfoCache.get_stop(destination)
      trip = %TripInfo{origin: origin_stop, destination: destination_stop, direction_id: direction_id}
      map_common_trips(schedules, trip_name_map, trip)
    end
  end

  defp map_trip_names(trips) do
    Map.new(trips, &do_map_trip_name/1)
  end

  defp do_map_trip_name(%{"type" => "trip", "id" => id, "attributes" => %{"name" => name}}), do: {id, name}
  defp do_map_trip_name(_), do: {nil, nil}

  defp map_common_trips([], _, _), do: :error
  defp map_common_trips(schedules, trip_names_map, trip) do
    schedules
    |> Enum.group_by(fn(%{"relationships" => %{"trip" => %{"data" => %{"id" => id}}}}) -> id end)
    |> Enum.filter(fn({_id, schedules}) -> Enum.count(schedules) > 1 end)
    |> Enum.map(fn({_id, schedules}) ->
        [departure_schedule, arrival_schedule] = Enum.sort_by(schedules, fn(%{"attributes" => %{"departure_time" => departure_timestamp}}) -> departure_timestamp end)
        %{"attributes" => %{
          "departure_time" => departure_timestamp
          },
          "relationships" => %{
            "trip" => %{
              "data" => %{
               "id" => trip_id
              }
            },
            "route" => %{
              "data" => %{
                "id" => route_id
              }
            }
          }
        } = departure_schedule

        %{"attributes" => %{"arrival_time" => arrival_timestamp}} = arrival_schedule
        {:ok, route} = ServiceInfoCache.get_route(route_id)

        %{trip | arrival_time: map_schedule_time(arrival_timestamp), departure_time: map_schedule_time(departure_timestamp), trip_number: Map.get(trip_names_map, trip_id), route: route}
      end)
    |> Enum.sort_by(fn(%TripInfo{departure_time: departure_time}) -> {~T[05:00:00] > departure_time, departure_time} end)
  end

  defp map_schedule_time(schedule_datetime) do
    schedule_datetime |> NaiveDateTime.from_iso8601! |> NaiveDateTime.to_time()
  end
end
