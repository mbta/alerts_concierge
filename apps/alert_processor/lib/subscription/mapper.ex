defmodule AlertProcessor.Subscription.Mapper do
  @moduledoc """
  Module for common subscription mapping functions to be imported into
  mode-specific mapper modules.
  """
  alias AlertProcessor.{Helpers.DateTimeHelper, Model.InformedEntity, Model.Route, Model.Subscription, Model.Trip, Model.User, ServiceInfoCache}
  alias Ecto.Multi

  @type map_trip_info_fn :: (String.t, String.t, Subscription.relevant_day -> :error | {:ok, [Trip.t]})

  def map_timeframe(%{"departure_start" => ds, "departure_end" => de, "return_start" => nil, "return_end" => nil, "relevant_days" => rd}) do
    {:ok, [do_map_timeframe(ds, de, rd)]}
  end
  def map_timeframe(%{"departure_start" => ds, "departure_end" => de, "return_start" => rs, "return_end" => re, "relevant_days" => rd}) do
    {:ok, [do_map_timeframe(ds, de, rd), do_map_timeframe(rs, re, rd)]}
  end
  def map_timeframe(_), do: :error

  def do_map_timeframe(start_time, end_time, relevant_days) do
    %Subscription{
      start_time: DateTime.to_time(start_time),
      end_time: DateTime.to_time(end_time),
      relevant_days: Enum.map(relevant_days, &String.to_existing_atom/1)
    }
  end

  def map_priority(subscriptions, %{"alert_priority_type" => alert_priority_type}) when is_list(subscriptions) do
    {:ok, Enum.map(subscriptions, fn(subscription) ->
      %{subscription | alert_priority_type: String.to_existing_atom(alert_priority_type)}
    end)}
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
        %InformedEntity{stop: origin, facility_type: String.to_existing_atom(amenity)}
      end)}
    end)
  end
  def map_amenities([subscription], %{"amenities" => amenities, "routes" => routes, "stops" => stops}) do
    [{subscription,
      Enum.flat_map(amenities, fn(amenity) ->
        route_amenities =
          Enum.map(routes, fn(route) ->
            %InformedEntity{route: String.capitalize(route), facility_type: String.to_existing_atom(amenity)}
          end)
        stop_amenities =
          Enum.map(stops, fn(stop) ->
            %InformedEntity{stop: stop, facility_type: String.to_existing_atom(amenity)}
          end)
        route_amenities ++ stop_amenities
      end)
    }]
  end
  def map_amenities(_, _), do: :error

  def map_route_type(subscription_infos, routes) do
    route_type_entities =
      Enum.map(routes, fn(%Route{route_type: type}) ->
        %InformedEntity{route_type: type}
      end)

    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ route_type_entities}
    end)
  end

  def map_routes(subscription_infos, %{"roaming" => "true"}, routes) do
    route_entities =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type}) ->
        [
          %InformedEntity{route: route, route_type: type},
          %InformedEntity{route: route, route_type: type, direction_id: 0},
          %InformedEntity{route: route, route_type: type, direction_id: 1}
        ]
      end)

    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ route_entities}
    end)
  end
  def map_routes([{subscription, informed_entities}], %{"origin" => origin, "destination" => destination}, routes) do
    route_entities =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type, stop_list: stop_list}) ->
        direction_id =
          case stop_list
            |> Enum.filter(fn({_name, id}) -> Enum.member?([origin, destination], id) end)
            |> Enum.map(fn({_name, id}) -> id end) do
            [^origin, ^destination] -> 1
            [^destination, ^origin] -> 0
          end
        [
          %InformedEntity{route: route, route_type: type},
          %InformedEntity{route: route, route_type: type, direction_id: direction_id}
        ]
      end)

    [{subscription, informed_entities ++ route_entities}]
  end
  def map_routes([{sub1, ie1}, {sub2, ie2}], _params, routes) do
    route_entities_1 =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type}) ->
        [
          %InformedEntity{route: route, route_type: type},
          %InformedEntity{route: route, route_type: type, direction_id: 0}
        ]
      end)
    route_entities_2 =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type}) ->
        [
          %InformedEntity{route: route, route_type: type},
          %InformedEntity{route: route, route_type: type, direction_id: 1}
        ]
      end)

    [{sub1, ie1 ++ route_entities_1}, {sub2, ie2 ++ route_entities_2}]
  end

  def map_stops([{sub1, ie1}, {sub2, ie2}], %{"origin" => origin, "destination" => destination}, routes) do
    stop_entities = map_stops_in_range(routes, origin, destination)

    {:ok, {origin_name, ^origin}} = ServiceInfoCache.get_stop(origin)
    {:ok, {destination_name, ^destination}} = ServiceInfoCache.get_stop(destination)

    [
      {
        Map.merge(sub1, %{origin: origin_name, destination: destination_name}),
        ie1 ++ stop_entities
      }, {
        Map.merge(sub2, %{origin: destination_name, destination: origin_name}),
        ie2 ++ stop_entities
      }
    ]
  end
  def map_stops([{subscription, informed_entities}], %{"origin" => origin, "destination" => destination}, routes) do
    stop_entities = map_stops_in_range(routes, origin, destination)

    {:ok, {origin_name, ^origin}} = ServiceInfoCache.get_stop(origin)
    {:ok, {destination_name, ^destination}} = ServiceInfoCache.get_stop(destination)

    [{Map.merge(subscription, %{origin: origin_name, destination: destination_name}), informed_entities ++ stop_entities}]
  end

  defp map_stops_in_range(routes, origin, destination) do
    Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type, stop_list: stop_list}) ->
      stop_list
      |> Enum.drop_while(fn({_k, v}) -> v != origin && v != destination end)
      |> Enum.reverse()
      |> Enum.drop_while(fn({_k, v}) -> v != origin && v != destination end)
      |> Enum.map(fn({_k, stop}) ->
        %InformedEntity{route: route, route_type: type, stop: stop}
      end)
    end)
  end

  def map_trips([{sub1, ie1}, {sub2, ie2}], %{"trips" => trips, "return_trips" => return_trips}) do
    trip_entities = Enum.map(trips, & %InformedEntity{trip: &1})
    return_trip_entities = Enum.map(return_trips, & %InformedEntity{trip: &1})

    [{sub1, ie1 ++ trip_entities}, {sub2, ie2 ++ return_trip_entities}]
  end
  def map_trips([{subscription, informed_entities}], %{"trips" => trips}) do
    trip_entities = Enum.map(trips, & %InformedEntity{trip: &1})

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
        Multi.run(accumulator, {:informed_entity, index, i}, fn _ ->
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
        "admin:create-subscription"
      end

    subscription_changeset = Subscription.create_changeset(subscription, params)
    current_trip_entities =
      subscription.informed_entities
      |> Enum.filter(& InformedEntity.entity_type(&1) == :trip)

    multi =
      trips
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn({trip, index}, acc) ->
           Multi.run(acc, {:informed_entity, index}, fn _ ->
             PaperTrail.insert(%InformedEntity{subscription_id: subscription.id, trip: trip}, originator: User.wrap_id(originator), meta: %{owner: subscription.user_id})
           end)
         end)

    current_trip_entities
    |> Enum.with_index()
    |> Enum.reduce(multi, fn({current_trip_entity, index}, acc) ->
          Multi.run(acc, {:remove_old, index}, fn _ ->
            PaperTrail.delete(current_trip_entity, originator: User.wrap_id(originator), meta: %{owner: subscription.user_id})
          end)
        end)
    |> Multi.run(:subscription, fn _ ->
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
    with {:ok, {_name, origin_id}} <- ServiceInfoCache.get_stop_by_name(subscription.origin),
         {:ok, {_name, destination_id}} <- ServiceInfoCache.get_stop_by_name(subscription.destination),
         [relevant_days] <- subscription.relevant_days,
         selected_trips <- Subscription.subscription_trip_ids(subscription) do
      get_trip_info(origin_id, destination_id, relevant_days, selected_trips, map_trip_options_fn)
    else
      _ -> :error
    end
  end
end
