defmodule AlertProcessor.Subscription.BusMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  bus into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  defdelegate build_subscription_transaction(subscriptions, user, originator), to: AlertProcessor.Subscription.Mapper

  @doc """
  map_subscription/1 receives a map of bus subscription params and returns
  arrays of subscription(s) and informed entities to creat in the database
  to be used for matching against alerts.
  """
  @spec map_subscription(map) :: {:ok, [Subscription.t], [InformedEntity.t]} | :error
  def map_subscription(subscription_params) do
    with {:ok, subscriptions} <- map_timeframe(subscription_params),
         {:ok, subscriptions} <- map_priority(subscriptions, subscription_params),
         subscriptions <- map_type(subscriptions, :bus)
         do
      map_entities(subscriptions, subscription_params)
    else
      _ -> :error
    end
  end

  defp map_entities(subscriptions, params) do
    with %{"routes" => routes} <- params,
         subscription_infos <- map_route_type(subscriptions),
         subscription_infos <- map_routes(subscription_infos, routes),
         subscription_infos <- filter_duplicate_entities(subscription_infos) do
      {:ok, subscription_infos}
    else
      _ -> :error
    end
  end

  defp map_route_type(subscriptions) do
    Enum.map(subscriptions, & {&1, [%InformedEntity{route_type: 3, activities: InformedEntity.default_entity_activities()}]})
  end

  defp map_routes([{sub, ie}], routes) do
    route_entities =
      routes
      |> String.split(",")
      |> Enum.flat_map(fn(route) ->
        {route_id, direction_id} = extract_route_and_direction(route)
        do_map_routes(:one_way, route_id, direction_id)
      end)
    [{sub, ie ++ route_entities}]
  end
  defp map_routes([{sub1, ie1}, {sub2, ie2}], routes) do
    {informed_entities_1, informed_entities_2} =
      routes
      |> String.split(",")
      |> Enum.reduce({ie1, ie2}, fn(route, {ie_1, ie_2}) ->
        {route_id, direction_id} = extract_route_and_direction(route)
        {route_entities_1, route_entities_2} = do_map_routes(:round_trip, route_id, direction_id)
        {ie_1 ++ route_entities_1, ie_2 ++ route_entities_2}
      end)
    [{sub1, informed_entities_1}, {sub2, informed_entities_2}]
  end

  defp do_map_routes(:one_way, route_id, direction_id) do
    do_map_route(route_id, 3, direction_id)
  end
  defp do_map_routes(:round_trip, route_id, 1) do
    route_entities_1 = do_map_route(route_id, 3, 1)
    route_entities_2 = do_map_route(route_id, 3, 0)

    {route_entities_1, route_entities_2}
  end
  defp do_map_routes(:round_trip, route_id, 0) do
    route_entities_1 = do_map_route(route_id, 3, 0)
    route_entities_2 = do_map_route(route_id, 3, 1)

    {route_entities_1, route_entities_2}
  end

  defp do_map_route(route, type, direction_id) do
    [
      %InformedEntity{route: route, route_type: type, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route: route, route_type: type, direction_id: direction_id, activities: InformedEntity.default_entity_activities()}
    ]
  end

  defp extract_route_and_direction(route) do
    [name, direction] = String.split(route, " - ")
    route_id = String.replace_leading(name, "Route ", "")
    {route_id, String.to_integer(direction)}
  end
end
