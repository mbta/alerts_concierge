defmodule AlertProcessor.Subscription.SubwayMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  subway into the relevant subscription and informed entity structs.
  """

  @route_type_map %{
    "Green-B" => 0,
    "Green-C" => 0,
    "Green-D" => 0,
    "Green-E" => 0,
    "Blue" => 1,
    "Orange" => 1,
    "Red" => 1
  }

  alias AlertProcessor.{Helpers.DateTimeHelper, ServiceInfoCache}
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  @doc """
  map_subscription/1 receives a map of subway subscription params and returns
  arrays of subscription(s) and informed entities to creat in the database
  to be used for matching against alerts.
  """
  @spec map_subscription(map) :: {:ok, [Subscription.t], [InformedEntity.t]} | :error
  def map_subscription(subscription_params) do
    with {:ok, subscriptions} <- map_timeframe(subscription_params),
         {:ok, subscriptions} <- map_priority(subscriptions, subscription_params),
         {:ok, subscriptions, informed_entities} <- map_entities(subscriptions, subscription_params) do
      {:ok, subscriptions, informed_entities}
    else
      _ -> :error
    end
  end

  defp map_timeframe(%{departure_start: ds, departure_end: de, return_start: nil, return_end: nil, relevant_days: rd}) do
    subscription = %Subscription{start_time: DateTimeHelper.timestamp_to_utc(ds), end_time: DateTimeHelper.timestamp_to_utc(de), relevant_days: Enum.map(rd, &String.to_existing_atom/1)}

    {:ok, [subscription]}
  end

  defp map_timeframe(%{departure_start: ds, departure_end: de, return_start: rs, return_end: re, relevant_days: rd}) do
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

    {:ok, [sub1, sub2]}
  end

  defp map_priority(subscriptions, %{alert_priority_type: alert_priority_type}) when is_list(subscriptions) do
    {:ok, Enum.map(subscriptions, fn(subscription) ->
      %{subscription | alert_priority_type: String.to_existing_atom(alert_priority_type)}
    end)}
  end

  defp map_entities(subscriptions, params) do
    with {:ok, subway_info} = ServiceInfoCache.get_subway_info(),
         %{origin: origin, destination: destination} <- params,
         route_maps <- Enum.filter(subway_info, fn({_route, stop_list}) -> List.keymember?(stop_list, origin, 1) && List.keymember?(stop_list, destination, 1) end),
         {subscriptions, informed_entities} <- map_amenities(subscriptions, params),
         {subscriptions, informed_entities} <- map_route_type(subscriptions, informed_entities, route_maps),
         {subscriptions, informed_entities} <- map_routes(subscriptions, informed_entities, route_maps),
         {subscriptions, informed_entities} <- map_stops(subscriptions, informed_entities, params, route_maps) do
      {:ok, subscriptions, informed_entities}
    else
      _ -> :error
    end
  end

  defp map_amenities(subscriptions, %{origin: origin, amenities: amenities}) do
    informed_entities =
      Enum.map(amenities, fn(amenity) ->
        %InformedEntity{stop: origin, facility_type: String.to_existing_atom(amenity)}
      end)

    {subscriptions, informed_entities}
  end

  defp map_route_type(subscriptions, informed_entities, route_maps) do
    route_type_entities =
      Enum.map(route_maps, fn({route, _stop_list}) ->
        %InformedEntity{route_type: @route_type_map[route]}
      end)

    {subscriptions, informed_entities ++ route_type_entities}
  end

  defp map_routes(subscriptions, informed_entities, route_maps) do
    route_entities =
      Enum.flat_map(route_maps, fn({route, _stop_list}) ->
        [
          %InformedEntity{route: route, route_type: @route_type_map[route]},
          %InformedEntity{route: route, route_type: @route_type_map[route], direction_id: 0},
          %InformedEntity{route: route, route_type: @route_type_map[route], direction_id: 1}
        ]
      end)

    {subscriptions, informed_entities ++ route_entities}
  end

  defp map_stops(subscriptions, informed_entities, %{origin: origin, destination: destination}, route_maps) do
    stop_entities =
      Enum.flat_map(route_maps, fn({route, _stop_list}) ->
        [%InformedEntity{route: route, route_type: @route_type_map[route], stop: origin}, %InformedEntity{route: route, route_type: @route_type_map[route], stop: destination}]
      end)

    {subscriptions, informed_entities ++ stop_entities}
  end
end
