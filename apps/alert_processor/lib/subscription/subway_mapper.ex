defmodule AlertProcessor.Subscription.SubwayMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  subway into the relevant subscription and informed entity structs.
  """

  alias AlertProcessor.{Helpers.DateTimeHelper, ServiceInfoCache}
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  @doc """
  map_subscription/1 receives a map of subway subscription params and returns
  arrays of subscription(s) and informed entities to creat in the database
  to be used for matching against alerts.
  """
  @spec map_subscription(map) :: {:ok, [{Subscription.t, InformedEntity.t}]} | :error
  def map_subscription(subscription_params) do
    with subscriptions <- map_timeframe(subscription_params),
         subscriptions <- map_priority(subscriptions, subscription_params),
         {:ok, subscriptions} <- map_entities(subscriptions, subscription_params) do
      {:ok, subscriptions}
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

  defp map_entities(subscriptions, params) do
    with {:ok, subway_info} = ServiceInfoCache.get_subway_info(),
         %{"origin" => origin, "destination" => destination} <- params,
         route_maps <- Enum.filter_map(
           subway_info,
           fn({{_route, _type, _direction_names}, stop_list}) -> List.keymember?(stop_list, origin, 1) && List.keymember?(stop_list, destination, 1) end,
           fn({{route, type, _direction_names}, stop_list}) -> {{route, type}, stop_list}
         end),
         subscriptions <- map_amenities(subscriptions, params),
         subscriptions <- map_route_type(subscriptions, route_maps),
         subscriptions <- map_routes(subscriptions, params, route_maps),
         subscriptions <- map_stops(subscriptions, params, route_maps) do
      {:ok, subscriptions}
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

  defp map_route_type(subscriptions, route_maps) do
    route_type_entities =
      Enum.map(route_maps, fn({{_route, type}, _stop_list}) ->
        %InformedEntity{route_type: type}
      end)

    Enum.map(subscriptions, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ route_type_entities}
    end)
  end

  defp map_routes(subscriptions, %{"roaming" => "true"}, route_maps) do
    route_entities =
      Enum.flat_map(route_maps, fn({{route, type}, _stop_list}) ->
        [
          %InformedEntity{route: route, route_type: type},
          %InformedEntity{route: route, route_type: type, direction_id: 0},
          %InformedEntity{route: route, route_type: type, direction_id: 1}
        ]
      end)

    Enum.map(subscriptions, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ route_entities}
    end)
  end

  defp map_routes([{subscription, informed_entities}], %{"origin" => origin, "destination" => destination}, route_maps) do
    route_entities =
      Enum.flat_map(route_maps, fn({{route, type}, stop_list}) ->
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

  defp map_routes([{sub1, ie1}, {sub2, ie2}], _params, route_maps) do
    route_entities_1 =
      Enum.flat_map(route_maps, fn({{route, type}, _stop_list}) ->
        [
          %InformedEntity{route: route, route_type: type},
          %InformedEntity{route: route, route_type: type, direction_id: 0}
        ]
      end)
    route_entities_2 =
      Enum.flat_map(route_maps, fn({{route, type}, _stop_list}) ->
        [
          %InformedEntity{route: route, route_type: type},
          %InformedEntity{route: route, route_type: type, direction_id: 1}
        ]
      end)

    [{sub1, ie1 ++ route_entities_1}, {sub2, ie2 ++ route_entities_2}]
  end

  defp map_stops(subscriptions, %{"origin" => origin, "destination" => destination, "roaming" => "true"}, route_maps) do
    stop_entities =
      Enum.flat_map(route_maps, fn({{route, type}, stop_list}) ->
        stop_list
        |> Enum.drop_while(fn({_k, v}) -> v != origin && v != destination end)
        |> Enum.reverse()
        |> Enum.drop_while(fn({_k, v}) -> v != origin && v != destination end)
        |> Enum.map(fn({_k, stop}) ->
          %InformedEntity{route: route, route_type: type, stop: stop}
        end)
      end)

    Enum.map(subscriptions, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ stop_entities}
    end)
  end

  defp map_stops(subscriptions, %{"origin" => origin, "destination" => destination}, route_maps) do
    stop_entities =
      Enum.flat_map(route_maps, fn({{route, type}, _stop_list}) ->
        [
          %InformedEntity{route: route, route_type: type, stop: origin},
          %InformedEntity{route: route, route_type: type, stop: destination}
        ]
      end)

    Enum.map(subscriptions, fn({subscription, informed_entities}) ->
      {subscription, informed_entities ++ stop_entities}
    end)
  end
end
