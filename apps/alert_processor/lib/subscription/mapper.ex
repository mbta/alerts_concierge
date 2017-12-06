defmodule AlertProcessor.Subscription.Mapper do
  @moduledoc """
  Module for common subscription mapping functions to be imported into
  mode-specific mapper modules.
  """
  alias AlertProcessor.{Helpers.DateTimeHelper, Model.InformedEntity, Model.Route, Model.Subscription, Model.Trip, Model.User}
  alias Ecto.Multi
  alias AlertProcessor.ServiceInfoCache

  @type map_trip_info_fn :: (String.t, String.t, Subscription.relevant_day -> :error | {:ok, [Trip.t]})

  def create_subscriptions(%{"return_start" => nil, "return_end" => nil} = params), do: [do_create_subscription(params)]
  def create_subscriptions(%{"origin" => origin, "destination" => destination} = params) do
    return_params = %{params | "destination" => origin, "origin" => destination,
                               "departure_start" => params["return_start"], "departure_end" => params["return_end"],
                               "direction" => flip_direction(params["direction"])}
    [do_create_subscription(params), do_create_subscription(return_params)]
  end
  def create_subscription(_), do: :error

  defp flip_direction(0), do: 1
  defp flip_direction(1), do: 0
  defp flip_direction(_), do: nil

  defp do_create_subscription(params) do
    subscription = %Subscription{
      start_time: params["departure_start"],
      end_time: params["departure_end"],
      relevant_days: Enum.map(params["relevant_days"], &String.to_existing_atom/1),
      origin: params["origin"],
      destination: params["destination"],
      route: params["route"],
      direction_id: params["direction"]
    }
    case {get_latlong_from_stop(params["origin"]), get_latlong_from_stop(params["destination"])} do
      {nil, nil} -> subscription
      {{origin_lat, origin_long}, {destination_lat, destination_long}} ->
        %{subscription | origin_lat: origin_lat, origin_long: origin_long, destination_lat: destination_lat,
                         destination_long: destination_long}
    end
  end

  defp get_latlong_from_stop(nil), do: nil
  defp get_latlong_from_stop(stop_id) do
    case ServiceInfoCache.get_stop(stop_id) do
      {:ok, stop} -> elem(stop, 2)
      _ -> nil
    end
  end

  def map_subscription_direction_id(subscriptions, %{stop_list: stop_list}) do
    Enum.map(subscriptions, fn(subscription) ->
      Map.put(subscription, :direction_id, map_direction_id(stop_list, subscription.origin, subscription.destination))
    end)
  end
  def map_subscription_direction_id(subscriptions, []), do: subscriptions

  def map_priority(subscriptions, %{"alert_priority_type" => alert_priority_type}) when is_list(subscriptions) do
    Enum.map(subscriptions, fn(subscription) ->
      %{subscription | alert_priority_type: String.to_existing_atom(alert_priority_type)}
    end)
  end
  def map_priority(_, _), do: :error

  def map_type(subscriptions, type) do
    Enum.map(subscriptions, fn(subscription) ->
      Map.put(subscription, :type, type)
    end)
  end

  def map_amenities(subscriptions, %{"origin" => origin, "amenities" => amenities}) do
    Enum.map(subscriptions, fn(subscription) ->
      {subscription, Enum.map(amenities, fn(amenity) ->
        amenity_type = String.to_existing_atom(amenity)
        %InformedEntity{stop: origin, facility_type: amenity_type, activities: map_amenity_activities(amenity_type) }
      end)}
    end)
  end
  def map_amenities([subscription], %{"amenities" => amenities, "routes" => routes, "stops" => stops}) do
    [{subscription,
      Enum.flat_map(amenities, fn(amenity) ->
        amenity_type = String.to_existing_atom(amenity)
        activities = map_amenity_activities(amenity_type)
        entities = for facility_type <- amenity_facility_types(amenity_type), do: %InformedEntity{facility_type: facility_type, activities: activities}
        route_entities = for route <- routes, entity <- entities, do: %{entity | route: String.capitalize(route)}
        stop_entities = for stop <- stops, entity <- entities, do: %{entity | stop: stop}

        route_entities ++ stop_entities
      end)
    }]
  end
  def map_amenities(_, _), do: :error

  def amenity_facility_types(:elevator), do: [:elevator, :portable_boarding_lift, :elevated_subplatform]
  def amenity_facility_types(amenity), do: [amenity]

  defp map_amenity_activities(:elevator), do: ["USING_WHEELCHAIR"]
  defp map_amenity_activities(:portable_boarding_lift), do: ["USING_WHEELCHAIR"]
  defp map_amenity_activities(:elevated_subplatform), do: ["USING_WHEELCHAIR"]
  defp map_amenity_activities(:escalator), do: ["USING_ESCALATOR"]
  defp map_amenity_activities(:bike_storage), do: ["STORE_BIKE"]
  defp map_amenity_activities(:parking_area), do: ["PARK_CAR"]
  defp map_amenity_activities(_), do: []

  def map_route_type(subscription_infos, %Route{route_type: type}) do
    route_type_entities = [%InformedEntity{route_type: type, activities: InformedEntity.default_entity_activities()}]

    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ route_type_entities}
    end)
  end

  def map_route(subscription_infos, %{"roaming" => "true"}, %Route{route_id: route, route_type: type}) do
    route_entities = [
      %InformedEntity{route: route, route_type: type, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route: route, route_type: type, direction_id: 0, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route: route, route_type: type, direction_id: 1, activities: InformedEntity.default_entity_activities()}
    ]

    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ route_entities}
    end)
  end
  def map_route([{subscription, informed_entities}], _params, %Route{route_id: route, route_type: type}) do
    route_entities = [
      %InformedEntity{route: route, route_type: type, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route: route, route_type: type, direction_id: subscription.direction_id, activities: InformedEntity.default_entity_activities()}
    ]

    [{subscription, informed_entities ++ route_entities}]
  end
  def map_route([{sub1, ie1}, {sub2, ie2}], _params, %Route{route_id: route, route_type: type}) do
    route_entities_1 = [
      %InformedEntity{route: route, route_type: type, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route: route, route_type: type, direction_id: sub1.direction_id, activities: InformedEntity.default_entity_activities()}
    ]
    route_entities_2 = [
      %InformedEntity{route: route, route_type: type, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route: route, route_type: type, direction_id: sub2.direction_id, activities: InformedEntity.default_entity_activities()}
    ]

    [{sub1, ie1 ++ route_entities_1}, {sub2, ie2 ++ route_entities_2}]
  end

  def map_stops([{sub1, ie1}, {sub2, ie2}], %{"origin" => origin, "destination" => destination}, route) do
    %Route{stop_list: stop_list} = route
    [end_stop1 | other_stops_in_range] = map_stops_in_range(route, origin, destination)
    direction_id_1 = map_direction_id(stop_list, origin, destination)
    [end_stop2 | other_stops_in_range] = Enum.reverse(other_stops_in_range)
    direction_id_2 = map_direction_id(stop_list, destination, origin)

    stop_entities_1 =
      Enum.flat_map(other_stops_in_range, fn(stop_entity) ->
        do_map_intermediate_stop(false, stop_entity, direction_id_1)
      end)
    end_stop_entities_1 =
      Enum.flat_map([end_stop1, end_stop2], fn(stop_entity) ->
        do_map_end_stop(false, stop_entity, origin, direction_id_1)
      end)

    stop_entities_2 =
      Enum.flat_map(other_stops_in_range, fn(stop_entity) ->
        do_map_intermediate_stop(false, stop_entity, direction_id_2)
      end)
    end_stop_entities_2 =
      Enum.flat_map([end_stop1, end_stop2], fn(stop_entity) ->
        do_map_end_stop(false, stop_entity, destination, direction_id_2)
      end)

    [
      {
        Map.merge(sub1, %{origin: origin, destination: destination}),
        ie1 ++ stop_entities_1 ++ end_stop_entities_1
      }, {
        Map.merge(sub2, %{origin: destination, destination: origin}),
        ie2 ++ stop_entities_2 ++ end_stop_entities_2
      }
    ]
  end
  def map_stops([{subscription, informed_entities}], %{"origin" => origin, "destination" => destination} = params, route) do
    %Route{stop_list: stop_list} = route
    {roaming_subscription, direction_ids} =
      case params do
        %{"roaming" => "true"} ->
          {true, [0, 1]}
        _ ->
          case stop_list
            |> Enum.filter(fn({_name, id, _latlong}) -> Enum.member?([origin, destination], id) end)
            |> Enum.map(fn({_name, id, _latlong}) -> id end) do
            [^origin, ^destination] -> {false, [1]}
            [^destination, ^origin] -> {false, [0]}
          end
      end

    [end_stop1 | other_stops_in_range] = map_stops_in_range(route, origin, destination)
    [end_stop2 | other_stops_in_range] = Enum.reverse(other_stops_in_range)
    stop_entities =
      Enum.flat_map(other_stops_in_range, fn(stop_entity) ->
        Enum.flat_map(direction_ids, &do_map_intermediate_stop(roaming_subscription, stop_entity, &1))
      end)
    end_stop_entities =
      Enum.flat_map([end_stop1, end_stop2], fn(stop_entity) ->
        Enum.flat_map(direction_ids, &do_map_end_stop(roaming_subscription, stop_entity, origin, &1))
      end)

    [{Map.merge(subscription, %{origin: origin, destination: destination}), informed_entities ++ stop_entities ++ end_stop_entities}]
  end

  defp do_map_intermediate_stop(true, stop_entity, direction_id) do
    [%{stop_entity | activities: InformedEntity.default_entity_activities()}, %{stop_entity | direction_id: direction_id, activities: InformedEntity.default_entity_activities()}]
  end
  defp do_map_intermediate_stop(false, stop_entity, direction_id) do
    [%{stop_entity | activities: ["RIDE"]}, %{stop_entity | direction_id: direction_id, activities: ["RIDE"]}]
  end

  defp do_map_end_stop(true, stop_entity, _, direction_id) do
    [%{stop_entity | activities: InformedEntity.default_entity_activities()}, %{stop_entity | direction_id: direction_id, activities: InformedEntity.default_entity_activities()}]
  end
  defp do_map_end_stop(false, %InformedEntity{stop: origin} = stop_entity, origin, direction_id) do
    [%{stop_entity | activities: ["BOARD"]}, %{stop_entity | direction_id: direction_id, activities: ["BOARD"]}]
  end
  defp do_map_end_stop(false, stop_entity, _origin, direction_id) do
    [%{stop_entity | activities: ["EXIT"]}, %{stop_entity | direction_id: direction_id, activities: ["EXIT"]}]
  end

  defp map_stops_in_range(%Route{route_id: route, route_type: type, stop_list: stop_list}, origin, destination) do
    stop_list
    |> Enum.drop_while(fn({_k, v, _latlong}) -> v != origin && v != destination end)
    |> Enum.reverse()
    |> Enum.drop_while(fn({_k, v, _latlong}) -> v != origin && v != destination end)
    |> Enum.map(fn({_k, stop, _latlong}) ->
      %InformedEntity{route: route, route_type: type, stop: stop}
    end)
    |> Enum.uniq()
  end

  def determine_direction_id(route, origin, destination) do
    filtered_stops =
      route.stop_list
      |> Enum.filter(fn({_name, id, _latlong}) -> Enum.member?([origin, destination], id) end)
      |> Enum.map(fn({_name, id, _latlong}) -> id end)
    case filtered_stops do
      [^origin, ^destination] -> 1
      [^destination, ^origin] -> 0
    end
  end

  defp map_direction_id(stop_list, origin, destination) do
    case stop_list
      |> Enum.filter(fn({_name, id, _latlong}) -> Enum.member?([origin, destination], id) end)
      |> Enum.map(fn({_name, id, _latlong}) -> id end) do
        [^origin, ^destination] -> 1
        [^destination, ^origin] -> 0
    end
  end

  def map_trips([{sub1, ie1}, {sub2, ie2}], %{"trips" => trips, "return_trips" => return_trips}) do
    trip_entities = Enum.map(trips, & %InformedEntity{trip: &1, activities: InformedEntity.default_entity_activities()})
    return_trip_entities = Enum.map(return_trips, & %InformedEntity{trip: &1})

    [{sub1, ie1 ++ trip_entities}, {sub2, ie2 ++ return_trip_entities}]
  end
  def map_trips([{subscription, informed_entities}], %{"trips" => trips}) do
    trip_entities = Enum.map(trips, & %InformedEntity{trip: &1, activities: InformedEntity.default_entity_activities()})

    [{subscription, informed_entities ++ trip_entities}]
  end

  def filter_duplicate_entities(subscription_infos) do
    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {subscription, Enum.uniq(informed_entities)}
    end)
  end

  def build_subscription_transaction(subscriptions, user, originator) do
    origin =
      if user.id != User.wrap_id(originator).id do
        "admin:create-subscription"
      end

    subscriptions
    |> Enum.with_index
    |> Enum.reduce(Multi.new, fn({{sub, ies}, index}, acc) ->
      uuid = Ecto.UUID.generate
      sub_to_insert = sub
      |> Map.merge(%{
        id: uuid,
        user_id: user.id
      })
      |> Subscription.create_changeset()

      acc = acc
      |> Multi.run({:subscription, index}, fn _ ->
           PaperTrail.insert(sub_to_insert, originator: User.wrap_id(originator), meta: %{owner: user.id}, origin: origin)
         end)

      ies
      |> Enum.with_index
      |> Enum.reduce(acc, fn({ie, i}, accumulator) ->
        Multi.run(accumulator, {:new_informed_entity, index, i}, fn _ ->
          ie_to_insert = ie
          |> Map.merge(%{
            subscription_id: uuid
          })
          PaperTrail.insert(ie_to_insert, originator: User.wrap_id(originator), meta: %{owner: user.id})
        end)
      end)
    end)
  end

  def build_update_subscription_transaction(subscription, %{"trips" => trips} = params, originator) do
    origin =
      if subscription.user_id != User.wrap_id(originator).id do
        "admin:update-subscription"
      end

    subscription_changeset = Subscription.create_changeset(subscription, params)
    current_trip_entities =
      subscription.informed_entities
      |> Enum.filter(& InformedEntity.entity_type(&1) == :trip)

    multi =
      trips
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn({trip, index}, acc) ->
           Multi.run(acc, {:new_informed_entity, index}, fn _ ->
             PaperTrail.insert(%InformedEntity{subscription_id: subscription.id, trip: trip, activities: InformedEntity.default_entity_activities()}, originator: User.wrap_id(originator), meta: %{owner: subscription.user_id})
           end)
         end)

    current_trip_entities
    |> Enum.with_index()
    |> Enum.reduce(multi, fn({current_trip_entity, index}, acc) ->
          Multi.run(acc, {:remove_old, index}, fn _ ->
            PaperTrail.delete(current_trip_entity, originator: User.wrap_id(originator), meta: %{owner: subscription.user_id})
          end)
        end)
    |> Multi.run({:subscription}, fn _ ->
         PaperTrail.update(subscription_changeset, originator: User.wrap_id(originator), meta: %{owner: subscription.user_id}, origin: origin)
       end)
  end

  @spec populate_trip_options(map, map_trip_info_fn) :: {:ok, map} | {:error, String.t}
  def populate_trip_options(%{"trip_type" => "one_way", "trips" => trips} = subscription_params, map_trip_options_fn) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days} = subscription_params
    case get_trip_info(origin, destination, relevant_days, trips, map_trip_options_fn) do
      {:ok, trips} ->
        {:ok, %{departure_trips: trips}}
      :error ->
        {:error, "Please correct the following errors to proceed: Please select a valid origin and destination combination."}
    end
  end
  def populate_trip_options(%{"trip_type" => "round_trip", "trips" => trips, "return_trips" => return_trips} = subscription_params, map_trip_options_fn) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days} = subscription_params
    with {:ok, departure_trips} <- get_trip_info(origin, destination, relevant_days, trips, map_trip_options_fn),
         {:ok, return_trips} <- get_trip_info(destination, origin, relevant_days, return_trips, map_trip_options_fn) do
      {:ok, %{departure_trips: departure_trips, return_trips: return_trips}}
    else
      _ -> {:error, "Please correct the following errors to proceed: Please select a valid origin and destination combination."}
    end
  end
  def populate_trip_options(%{"trip_type" => "one_way"} = subscription_params, map_trip_options_fn) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days, "departure_start" => ds} = subscription_params
    case get_trip_info(origin, destination, relevant_days, ds, map_trip_options_fn) do
      {:ok, trips} ->
        {:ok, %{departure_trips: trips}}
      :error ->
        {:error, "Please correct the following errors to proceed: Please select a valid origin and destination combination."}
    end
  end
  def populate_trip_options(%{"trip_type" => "round_trip"} = subscription_params, map_trip_options_fn) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days, "departure_start" => ds, "return_start" => rs} = subscription_params
    with {:ok, departure_trips} <- get_trip_info(origin, destination, relevant_days, ds, map_trip_options_fn),
         {:ok, return_trips} <- get_trip_info(destination, origin, relevant_days, rs, map_trip_options_fn) do
      {:ok, %{departure_trips: departure_trips, return_trips: return_trips}}
    else
      _ -> {:error, "Please correct the following errors to proceed: Please select a valid origin and destination combination."}
    end
  end

  @spec get_trip_info(Route.stop_id, Route.stop_id, Subscription.relevant_day, [Trip.id] | String.t, map_trip_info_fn) :: {:ok, [Trip.t]} | :error
  def get_trip_info(origin, destination, relevant_days, selected_trip_numbers, map_trip_options_fn) when is_list(selected_trip_numbers) do
    case map_trip_options_fn.(origin, destination, relevant_days) do
      {:ok, trips} ->
        updated_trips =
          for trip <- trips do
            if Enum.member?(selected_trip_numbers, trip.trip_number) do
              %{trip | selected: true}
            else
              %{trip | selected: false}
            end
          end
        {:ok, updated_trips}
      _ ->
        :error
    end
  end
  def get_trip_info(origin, destination, relevant_days, timestamp, map_trip_options_fn) do
    case map_trip_options_fn.(origin, destination, relevant_days) do
      {:ok, []} ->
        :error
      {:ok, trips} ->
        departure_start = timestamp |> Time.from_iso8601!() |> DateTimeHelper.seconds_of_day()
        closest_trip = Enum.min_by(trips, &calculate_difference(&1, departure_start))
        updated_trips =
          for trip <- trips do
            if trip.trip_number == closest_trip.trip_number do
              %{trip | selected: true}
            else
              %{trip | selected: false}
            end
          end
        {:ok, updated_trips}
      _ ->
        :error
    end
  end

  defp calculate_difference(trip, departure_start) do
    departure_time = DateTimeHelper.seconds_of_day(trip.departure_time)
    abs(departure_start - departure_time)
  end

  @spec get_trip_info_from_subscription(Subscription.t, map_trip_info_fn) :: {:ok, [Trip.t]} | :error
  def get_trip_info_from_subscription(subscription, map_trip_options_fn) do
    with [relevant_days] <- subscription.relevant_days,
         selected_trips <- Subscription.subscription_trip_ids(subscription) do
      get_trip_info(subscription.origin, subscription.destination, relevant_days, selected_trips, map_trip_options_fn)
    else
      _ -> :error
    end
  end
end
