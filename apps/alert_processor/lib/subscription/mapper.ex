defmodule AlertProcessor.Subscription.Mapper do
  @moduledoc """
  Module for common subscription mapping functions to be imported into
  mode-specific mapper modules.
  """
  alias AlertProcessor.{Helpers.DateTimeHelper, Model.InformedEntity, Model.Route, Model.Subscription, Model.Trip, ServiceInfoCache}
  alias Ecto.Multi
  import Ecto.Query

  def map_timeframe(%{"departure_start" => ds, "departure_end" => de, "return_start" => nil, "return_end" => nil, "relevant_days" => rd}) do
    {:ok, [do_map_timeframe(ds, de, rd)]}
  end
  def map_timeframe(%{"departure_start" => ds, "departure_end" => de, "return_start" => rs, "return_end" => re, "relevant_days" => rd}) do
    {:ok, [do_map_timeframe(ds, de, rd), do_map_timeframe(rs, re, rd)]}
  end
  def map_timeframe(_), do: :error

  def do_map_timeframe(start_time, end_time, relevant_days) do
    %Subscription{
      start_time: DateTimeHelper.timestamp_to_utc(start_time),
      end_time: DateTimeHelper.timestamp_to_utc(end_time),
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

  def map_stops(subscription_infos, %{"origin" => origin, "destination" => destination, "roaming" => "true"}, routes) do
    stop_entities =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type, stop_list: stop_list}) ->
        stop_list
        |> Enum.drop_while(fn({_k, v}) -> v != origin && v != destination end)
        |> Enum.reverse()
        |> Enum.drop_while(fn({_k, v}) -> v != origin && v != destination end)
        |> Enum.map(fn({_k, stop}) ->
          %InformedEntity{route: route, route_type: type, stop: stop}
        end)
      end)

    {:ok, {origin_name, ^origin}} = ServiceInfoCache.get_stop(origin)
    {:ok, {destination_name, ^destination}} = ServiceInfoCache.get_stop(destination)

    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {Map.merge(subscription, %{origin: origin_name, destination: destination_name}), informed_entities ++ stop_entities}
    end)
  end
  def map_stops([{sub1, ie1}, {sub2, ie2}], %{"origin" => origin, "destination" => destination}, routes) do
    stop_entities =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type}) ->
        [
          %InformedEntity{route: route, route_type: type, stop: origin},
          %InformedEntity{route: route, route_type: type, stop: destination}
        ]
      end)

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
    stop_entities =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type}) ->
        [
          %InformedEntity{route: route, route_type: type, stop: origin},
          %InformedEntity{route: route, route_type: type, stop: destination}
        ]
      end)

    {:ok, {origin_name, ^origin}} = ServiceInfoCache.get_stop(origin)
    {:ok, {destination_name, ^destination}} = ServiceInfoCache.get_stop(destination)

    [{Map.merge(subscription, %{origin: origin_name, destination: destination_name}), informed_entities ++ stop_entities}]
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

  def build_subscription_transaction(subscriptions, user) do
    subscriptions
    |> Enum.with_index
    |> Enum.reduce(Multi.new, fn({{sub, ies}, index}, acc) ->
      sub_to_insert = sub
      |> Map.merge(%{
        user_id: user.id,
        informed_entities: ies
      })
      |> Subscription.create_changeset()

      acc
      |> Multi.insert({:subscription, index}, sub_to_insert)
    end)
  end

  def build_update_subscription_transaction(subscription, %{"trips" => trips} = params) do
    subscription_changeset = Subscription.create_changeset(subscription, params)
    current_trip_entity_ids =
      subscription.informed_entities
      |> Enum.filter(& InformedEntity.entity_type(&1) == :trip)
      |> Enum.map(& &1.id)

    trips
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn({trip, index}, acc) ->
         Multi.insert(acc, {:informed_entity, index}, %InformedEntity{subscription_id: subscription.id, trip: trip})
       end)
    |> Multi.delete_all(:remove_old, from(ie in InformedEntity, where: ie.id in ^current_trip_entity_ids))
    |> Multi.update(:subscription, subscription_changeset)
  end

  @spec populate_trip_options(map, (String.t, String.t, Subscription.relevant_day -> :error | {:ok, [Trip.t]})) :: {:ok, map} | {:error, String.t}
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

  @spec get_trip_info(Route.stop_id, Route.stop_id, Subscription.relevant_day, [Trip.id] | String.t, (String.t, String.t, Subscription.relevant_day -> :error | {:ok, [Trip.t]})) :: {:ok, [Trip.t]} | :error
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
end
