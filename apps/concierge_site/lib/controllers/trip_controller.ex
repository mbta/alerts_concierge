defmodule ConciergeSite.TripController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{Trip, Subscription, User}
  alias AlertProcessor.ServiceInfoCache
  alias ConciergeSite.ParamParsers.{ParamTime, TripParams}
  alias ConciergeSite.Schedule
  alias Ecto.Multi

  plug(:scrub_params, "trip" when action in [:create, :leg])

  action_fallback(ConciergeSite.FallbackController)

  @valid_facility_types ~w(bike_storage elevator escalator parking_area)

  def index(conn, _params, user, _claims) do
    trips = Trip.get_trips_by_user(user.id)
    render(conn, "index.html", trips: trips, user_id: user.id)
  end

  def new(conn, _params, user, _claims) do
    trips = Trip.get_trips_by_user(user.id)
    render(conn, "new.html", trips: trips)
  end

  def create(conn, %{"trip" => trip_params}, user, {:ok, claims}) do
    params = parse_input(trip_params)
    subscriptions = input_to_subscriptions(user, params)
    trip = input_to_trip(user, params)
    multi = build_trip_transaction(trip, subscriptions, user, Map.get(claims, "imp", user.id))

    with :ok <- validate_relevant_days(trip_params),
         :ok <- Subscription.set_versioned_subscription(multi) do
      conn
      |> put_flash(:info, "Success! Your subscription has been created.")
      |> redirect(to: trip_path(conn, :index))
    else
      {:error, :relevant_days} ->
        conn
        |> put_flash(:error, "You must select at least one day for your trip.")
        |> render("new.html")

      _ ->
        conn
        |> put_flash(:error, "There was an error creating your trip. Please try again.")
        |> render("new.html")
    end
  end

  defp validate_relevant_days(trip_params) do
    relevant_days? = "relevant_days" in Map.keys(trip_params)
    if relevant_days?, do: :ok, else: {:error, :relevant_days}
  end

  def edit(conn, %{"id" => id}, user, _claims) do
    with {:trip, %Trip{} = trip} <- {:trip, Trip.find_by_id(id)},
         {:authorized, true} <- {:authorized, user.id == trip.user_id},
         {:changeset, changeset} <- {:changeset, Trip.update_changeset(trip)} do
      schedules = Schedule.get_schedules_for_trip(trip.subscriptions, false)
      return_schedules = Schedule.get_schedules_for_trip(trip.subscriptions, true)

      render(
        conn,
        "edit.html",
        trip: trip,
        changeset: changeset,
        schedules: schedules,
        return_schedules: return_schedules,
        travel_times: travel_times_by_route(trip.subscriptions, false),
        return_travel_times: travel_times_by_route(trip.subscriptions, true)
      )
    else
      {:trip, nil} ->
        {:error, :not_found}

      {:authorized, false} ->
        {:error, :not_found}
    end
  end

  defp travel_times_by_route(subscriptions, return_trip) do
    Enum.reduce(subscriptions, %{}, fn leg, accumulator ->
      if leg.return_trip == return_trip do
        Map.put(accumulator, leg.route, {leg.travel_start_time, leg.travel_end_time})
      else
        accumulator
      end
    end)
  end

  def update(conn, %{"id" => id, "trip" => trip_params}, user, _claims) do
    with {:trip, %Trip{} = trip} <- {:trip, Trip.find_by_id(id)},
         {:authorized, true} <- {:authorized, user.id == trip.user_id},
         {:collated_facility_types, collated_trip_params} <-
           {:collated_facility_types,
            TripParams.collate_facility_types(trip_params, @valid_facility_types)},
         {:sanitized, leg_params, updated_trip_params} <-
           sanitize_leg_params(collated_trip_params),
         {:sanitized, sanitized_trip_params} <-
           {:sanitized, TripParams.sanitize_trip_params(updated_trip_params)},
         {:ok, %Trip{}} <- Trip.update(trip, sanitized_trip_params),
         {:ok, true} <- update_trip_legs(trip.subscriptions, leg_params) do
      conn
      |> put_flash(:info, "Subscription updated.")
      |> redirect(to: trip_path(conn, :index))
    else
      {:trip, nil} ->
        {:error, :not_found}

      {:authorized, false} ->
        {:error, :not_found}

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Trip could not be updated. Please see errors below.")
        |> render(
          "edit.html",
          trip: Trip.find_by_id(id),
          changeset: changeset,
          schedules: %{},
          return_schedules: %{},
          travel_times: %{},
          return_travel_times: %{}
        )
    end
  end

  def leg(conn, %{"trip" => %{"origin" => origin, "destination" => destination}}, _, _)
      when not is_nil(origin) and origin == destination do
    conn
    |> put_flash(:error, "There was an error. Trip origin and destination must be different.")
    |> render("new.html")
  end

  def leg(conn, %{"trip" => trip}, user, _claims) do
    case trip do
      %{
        "route" => route,
        "saved_leg" => saved_leg,
        "origin" => origin,
        "destination" => destination,
        "round_trip" => round_trip,
        "new_leg" => "true",
        "saved_mode" => saved_mode
      } ->
        [leg, route_name, mode] = String.split(route, "~~")

        {legs, origins, destinations, modes} =
          parse_legs(trip, saved_leg, origin, destination, saved_mode)

        conn = %{conn | params: %{}}

        render(
          conn,
          "leg.html",
          legs: legs,
          origins: origins,
          destinations: destinations,
          headsigns: get_headsigns(leg),
          round_trip: round_trip,
          route_name: route_name,
          mode: mode,
          saved_leg: leg,
          saved_mode: mode,
          modes: modes,
          default_origin: [List.first(destinations)]
        )

      %{
        "saved_leg" => saved_leg,
        "origin" => origin,
        "destination" => destination,
        "round_trip" => round_trip,
        "new_leg" => "false",
        "saved_mode" => saved_mode
      } ->
        {legs, origins, destinations, modes} =
          parse_legs(trip, saved_leg, origin, destination, saved_mode)

        conn = %{conn | params: %{}}
        schedules = Schedule.get_schedules_for_input(legs, origins, destinations, modes)
        return_schedules = Schedule.get_schedules_for_input(legs, destinations, origins, modes)

        render(
          conn,
          "times.html",
          legs: legs,
          origins: origins,
          destinations: destinations,
          round_trip: round_trip,
          modes: modes,
          schedules: schedules,
          return_schedules: return_schedules,
          partial_subscriptions:
            input_to_subscriptions(user, %{
              "partial" => true,
              "modes" => modes,
              "legs" => legs,
              "origins" => origins,
              "destinations" => destinations,
              "round_trip" => round_trip,
              "combine_greenline_routes" => true
            })
        )

      %{"route" => route, "round_trip" => round_trip, "from_new_trip" => "true"} ->
        [leg, route_name, mode] = String.split(route, "~~")
        conn = %{conn | params: %{}}

        render(
          conn,
          "leg.html",
          legs: [],
          origins: [],
          destinations: [],
          headsigns: get_headsigns(leg),
          round_trip: round_trip,
          route_name: route_name,
          saved_mode: mode,
          saved_leg: leg,
          modes: [],
          default_origin: []
        )

      _ ->
        conn = put_flash(conn, :error, "There was an error creating your trip. Please try again.")
        render(conn, "new.html")
    end
  end

  def times(
        conn,
        %{
          "trip" => %{
            "legs" => legs,
            "origins" => origins,
            "destinations" => destinations,
            "modes" => modes,
            "round_trip" => round_trip
          }
        },
        user,
        _claims
      ) do
    schedules = Schedule.get_schedules_for_input(legs, origins, destinations, modes)
    return_schedules = Schedule.get_schedules_for_input(legs, destinations, origins, modes)

    render(
      conn,
      "times.html",
      legs: legs,
      origins: origins,
      destinations: destinations,
      modes: modes,
      round_trip: round_trip,
      schedules: schedules,
      return_schedules: return_schedules,
      partial_subscriptions:
        input_to_subscriptions(user, %{
          "partial" => true,
          "modes" => modes,
          "legs" => legs,
          "origins" => origins,
          "destinations" => destinations,
          "round_trip" => round_trip,
          "combine_greenline_routes" => true
        })
    )
  end

  def delete(conn, %{"id" => id}, user, _claims) do
    with %Trip{} = trip <- Trip.find_by_id(id),
         true <- user.id == trip.user_id,
         {:ok, %Trip{}} <- Trip.delete(trip) do
      conn
      |> put_flash(:info, "Subscription deleted.")
      |> redirect(to: trip_path(conn, :index))
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

  defp build_trip_transaction(trip, subscriptions, user, originator) do
    trip_id = Ecto.UUID.generate()
    trip = Map.put(trip, :id, trip_id)

    multi =
      Multi.run(Multi.new(), {:trip, 0}, fn _ ->
        PaperTrail.insert(trip, originator: User.wrap_id(originator), meta: %{owner: user.id})
      end)

    subscriptions
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {sub, index}, acc ->
      sub_to_insert =
        sub
        |> Map.merge(%{
          id: Ecto.UUID.generate(),
          user_id: user.id,
          trip_id: trip.id,
          facility_types: trip.facility_types
        })
        |> Subscription.create_changeset()

      acc
      |> Multi.run({:subscription, index}, fn _ ->
        PaperTrail.insert(
          sub_to_insert,
          originator: User.wrap_id(originator),
          meta: %{owner: user.id}
        )
      end)
    end)
  end

  defp parse_input(params) do
    params
    |> Map.put("relevant_days", Map.get(params, "relevant_days", []))
    |> Map.put("start_time", ParamTime.to_time(params["start_time"]))
    |> Map.put("end_time", ParamTime.to_time(params["end_time"]))
    |> Map.put("return_start_time", ParamTime.to_time(params["return_start_time"]))
    |> Map.put("return_end_time", ParamTime.to_time(params["return_end_time"]))
    |> Map.put("schedule_start", parse_schedule_input(params, "schedule_start"))
    |> Map.put("schedule_return", parse_schedule_input(params, "schedule_return"))
  end

  defp parse_schedule_input(params, field) do
    params
    |> Map.get(field, %{})
    |> Enum.reduce(%{}, fn {route_id, travel_times}, accumulator ->
      Map.put(accumulator, route_id, Enum.map(travel_times, &Time.from_iso8601!(&1)))
    end)
  end

  defp input_to_subscriptions(user, params) do
    {:ok, subway_routes} = ServiceInfoCache.get_subway_full_routes()

    Enum.zip([
      Enum.reverse(params["modes"]),
      Enum.reverse(params["legs"]),
      Enum.reverse(params["origins"]),
      Enum.reverse(params["destinations"]),
      Stream.iterate(0, &(&1 + 1))
    ])
    |> Enum.flat_map(fn {type, route_in, origin, destination, rank} ->
      {route_id, direction} = determine_route(route_in)
      route_filter = %{route_id: route_id, stop_ids: [origin, destination]}
      {:ok, route} = ServiceInfoCache.get_route(route_filter)

      %Subscription{
        alert_priority_type: "low",
        user_id: user.id,
        relevant_days: Enum.map(params["relevant_days"] || [], &String.to_existing_atom/1),
        start_time: params["start_time"],
        end_time: params["end_time"],
        origin: origin,
        destination: destination,
        type: type,
        route: route_id,
        route_type: route.route_type,
        direction_id:
          Schedule.determine_direction_id(route.stop_list, direction, origin, destination),
        rank: rank,
        return_trip: false,
        travel_start_time: List.first(travel_times(params["schedule_start"] || %{}, route_id)),
        travel_end_time: List.last(travel_times(params["schedule_start"] || %{}, route_id))
      }
      |> Subscription.add_latlong_to_subscription(origin, destination)
      |> add_return_subscription(params)
    end)
    |> Enum.flat_map(
      &expand_multiroute_greenline_subscription(
        &1,
        subway_routes,
        params["combine_greenline_routes"]
      )
    )
  end

  defp travel_times(schedule, route_id), do: Map.get(schedule, route_id, [])

  defp expand_multiroute_greenline_subscription(
         %{route_type: 0, origin: origin, destination: destination} = subscription,
         subway_routes,
         combine_greenline_routes
       ) do
    routes = get_route_intersection(subway_routes, origin, destination)

    if combine_greenline_routes do
      [Map.put(subscription, :route, MapSet.to_list(routes))]
    else
      copy_subscription_for_routes(routes, subscription)
    end
  end

  defp expand_multiroute_greenline_subscription(subscription, _routes, _combine_greenline_routes),
    do: [subscription]

  defp copy_subscription_for_routes(routes, subscription) do
    Enum.map(routes, fn route_id ->
      %{subscription | route: route_id}
    end)
  end

  defp get_route_intersection(routes, origin, destination) do
    origin_routes = get_routes_for_stop(routes, origin)
    destination_routes = get_routes_for_stop(routes, destination)
    MapSet.intersection(MapSet.new(origin_routes), MapSet.new(destination_routes))
  end

  defp get_routes_for_stop(routes, stop_id) do
    Enum.flat_map(routes, fn %{stop_list: stop_list, route_id: route_id} ->
      if Enum.any?(stop_list, fn {_, match, _, _} -> match == stop_id end) do
        [route_id]
      else
        []
      end
    end)
  end

  defp add_return_subscription(subscription, %{
         "round_trip" => "true",
         "return_start_time" => return_start_time,
         "return_end_time" => return_end_time,
         "schedule_return" => schedule_return
       }) do
    return_subscription = %{
      subscription
      | start_time: return_start_time,
        end_time: return_end_time,
        origin: subscription.destination,
        origin_lat: subscription.destination_lat,
        origin_long: subscription.destination_long,
        destination: subscription.origin,
        destination_lat: subscription.origin_lat,
        destination_long: subscription.origin_long,
        direction_id: flip_direction(subscription.direction_id),
        return_trip: true,
        travel_start_time: List.first(travel_times(schedule_return, subscription.route)),
        travel_end_time: List.last(travel_times(schedule_return, subscription.route))
    }

    [subscription, return_subscription]
  end

  defp add_return_subscription(subscription, %{"partial" => true, "round_trip" => "true"}) do
    return_subscription = %{
      subscription
      | origin: subscription.destination,
        origin_lat: subscription.destination_lat,
        origin_long: subscription.destination_long,
        destination: subscription.origin,
        destination_lat: subscription.origin_lat,
        destination_long: subscription.origin_long,
        direction_id: flip_direction(subscription.direction_id),
        return_trip: true
    }

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
      facility_types: TripParams.input_to_facility_types(params, @valid_facility_types),
      roundtrip: params["round_trip"] == "true"
    }
  end

  defp flip_direction(0), do: 1
  defp flip_direction(1), do: 0

  defp determine_route(route_id) do
    route_id
    |> String.split(" - ")
    |> Enum.reduce({}, fn part, acc ->
      if acc == {} do
        {part, nil}
      else
        {elem(acc, 0), part}
      end
    end)
  end

  defp update_trip_legs(_, %{"schedule_start" => nil, "schedule_return" => nil}), do: {:ok, true}

  defp update_trip_legs(subscriptions, %{
         "schedule_start" => schedule_start,
         "schedule_return" => schedule_return
       }) do
    for subscription <- subscriptions do
      trip_times = if subscription.return_trip, do: schedule_return, else: schedule_start
      update_leg_travel_time(subscription, Map.get(trip_times, subscription.route))
    end

    {:ok, true}
  end

  defp update_leg_travel_time(_, nil), do: :ok

  defp update_leg_travel_time(subscription, trip_times) do
    subscription
    |> Subscription.create_changeset(%{
      travel_start_time: List.first(trip_times),
      travel_end_time: List.last(trip_times)
    })
    |> Repo.update!()
  end

  defp sanitize_leg_params(params) do
    leg_params = %{
      "schedule_start" => sanitize_travel_times(Map.get(params, "schedule_start")),
      "schedule_return" => sanitize_travel_times(Map.get(params, "schedule_return"))
    }

    {:sanitized, leg_params, Map.drop(params, ["schedule_start", "schedule_return"])}
  end

  defp sanitize_travel_times(nil), do: nil

  defp sanitize_travel_times(travel_times) do
    Enum.reduce(travel_times, %{}, fn {route_id, times}, acc ->
      Map.put(acc, route_id, Enum.map(times, &Time.from_iso8601!(&1)))
    end)
  end

  defp get_headsigns(route_id) do
    with {:ok, %{headsigns: headsigns}} <-
           ServiceInfoCache.get_route(String.replace_suffix(route_id, " - 1", "")) do
      headsigns
    end
  end
end