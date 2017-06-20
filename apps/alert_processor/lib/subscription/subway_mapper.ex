defmodule AlertProcessor.Subscription.SubwayMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  subway into the relevant subscription and informed entity structs.
  """

  alias AlertProcessor.{Helpers.DateTimeHelper, ServiceInfoCache}
  alias AlertProcessor.Model.{InformedEntity, Route, Subscription}

  @type subscription_info :: {Subscription.t, [InformedEntity.t]}

  @doc """
  map_subscription/1 receives a map of subway subscription params and returns
  arrays of subscription_info to create in the database
  to be used for matching against alerts.
  """
  @spec map_subscriptions(map) :: {:ok, [subscription_info]} | :error
  def map_subscriptions(subscription_params) do
    with subscriptions <- map_timeframe(subscription_params),
         subscriptions <- map_priority(subscriptions, subscription_params),
         subscriptions <- map_type(subscriptions),
         {:ok, subscription_infos} <- map_entities(subscriptions, subscription_params)
          do
      {:ok, subscription_infos}
    else
      _ -> :error
    end
  end

  defp map_timeframe(%{"departure_start" => ds, "departure_end" => de, "return_start" => nil, "return_end" => nil, "relevant_days" => rd}) do
    [%Subscription{start_time: DateTimeHelper.timestamp_to_utc(ds), end_time: DateTimeHelper.timestamp_to_utc(de), relevant_days: Enum.map(rd, &String.to_existing_atom/1)}]
  end

  defp map_timeframe(%{"departure_start" => ds, "departure_end" => de, "return_start" => rs, "return_end" => re, "relevant_days" => rd}) do
    sub1 =
      %Subscription{
        start_time: DateTimeHelper.timestamp_to_utc(ds),
        end_time: DateTimeHelper.timestamp_to_utc(de),
        relevant_days: Enum.map(rd, &String.to_existing_atom/1)
      }
    sub2 =
      %Subscription{
        start_time: DateTimeHelper.timestamp_to_utc(rs),
        end_time: DateTimeHelper.timestamp_to_utc(re),
        relevant_days: Enum.map(rd, &String.to_existing_atom/1)
      }

    [sub1, sub2]
  end

  defp map_priority(subscriptions, %{"alert_priority_type" => alert_priority_type}) when is_list(subscriptions) do
    Enum.map(subscriptions, fn(subscription) ->
      %{subscription | alert_priority_type: String.to_existing_atom(alert_priority_type)}
    end)
  end

  defp map_type(subscriptions) do
    Enum.map(subscriptions, fn(subscription) ->
      Map.put(subscription, :type, :subway)
    end)
  end

  defp map_entities(subscriptions, params) do
    with {:ok, subway_info} = ServiceInfoCache.get_subway_info(),
         %{"origin" => origin, "destination" => destination} <- params,
         routes <- Enum.filter(
           subway_info,
           fn(%Route{stop_list: stop_list}) -> List.keymember?(stop_list, origin, 1) && List.keymember?(stop_list, destination, 1)
         end),
         subscription_infos <- map_amenities(subscriptions, params),
         subscription_infos <- map_route_type(subscription_infos, routes),
         subscription_infos <- map_routes(subscription_infos, params, routes),
         subscription_infos <- map_stops(subscription_infos, params, routes),
         subscription_infos <- filter_duplicate_entities(subscription_infos) do
      {:ok, subscription_infos}
    else
      _ -> :error
    end
  end

  defp map_amenities(subscriptions, %{"origin" => origin, "amenities" => amenities}) do
    Enum.map(subscriptions, fn(subscription) ->
      {subscription, Enum.map(amenities, fn(amenity) ->
        %InformedEntity{stop: origin, facility_type: String.to_existing_atom(amenity)}
      end)}
    end)
  end

  defp map_route_type(subscription_infos, routes) do
    route_type_entities =
      Enum.map(routes, fn(%Route{route_type: type}) ->
        %InformedEntity{route_type: type}
      end)

    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ route_type_entities}
    end)
  end

  defp map_routes(subscription_infos, %{"roaming" => "true"}, routes) do
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

  defp map_routes([{subscription, informed_entities}], %{"origin" => origin, "destination" => destination}, routes) do
    route_entities =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type, stop_list: stop_list}) ->
        direction_id =
          case Enum.filter_map(
            stop_list,
            fn({_name, id}) -> Enum.member?([origin, destination], id) end,
            fn({_name, id}) -> id
          end) do
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

  defp map_routes([{sub1, ie1}, {sub2, ie2}], _params, routes) do
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

  defp map_stops(subscription_infos, %{"origin" => origin, "destination" => destination, "roaming" => "true"}, routes) do
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

  defp map_stops([{sub1, ie1}, {sub2, ie2}], %{"origin" => origin, "destination" => destination}, routes) do
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

  defp map_stops(subscription_infos, %{"origin" => origin, "destination" => destination}, routes) do
    stop_entities =
      Enum.flat_map(routes, fn(%Route{route_id: route, route_type: type}) ->
        [
          %InformedEntity{route: route, route_type: type, stop: origin},
          %InformedEntity{route: route, route_type: type, stop: destination}
        ]
      end)

    {:ok, {origin_name, ^origin}} = ServiceInfoCache.get_stop(origin)
    {:ok, {destination_name, ^destination}} = ServiceInfoCache.get_stop(destination)

    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {Map.merge(subscription, %{origin: origin_name, destination: destination_name}), informed_entities ++ stop_entities}
    end)
  end

  defp filter_duplicate_entities(subscription_infos) do
    Enum.map(subscription_infos, fn({subscription, informed_entities}) ->
      {subscription, Enum.uniq(informed_entities)}
    end)
  end
end
