defmodule AlertProcessor.Subscription.BusMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  bus into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  @doc """
  map_subscription/1 receives a map of bus subscription params and returns
  arrays of subscription(s) and informed entities to creat in the database
  to be used for matching against alerts.
  """
  @spec map_subscription(map) :: {:ok, [Subscription.t], [InformedEntity.t]} | :error
  def map_subscription(subscription_params) do
    with subscriptions <- map_timeframe(subscription_params),
         subscriptions <- map_priority(subscriptions, subscription_params),
         subscriptions <- map_type(subscriptions, :bus)
         do
      map_entities(subscriptions, subscription_params)
    end
  end

  defp map_entities(subscriptions, params) do
    with %{"route" => route} <- params,
         {route_id, direction_id} = extract_route_and_direction(route),
         subscription_infos <- map_route_type(subscriptions),
         subscription_infos <- map_routes(subscription_infos, params, route_id, direction_id),
         subscription_infos <- filter_duplicate_entities(subscription_infos) do
      {:ok, subscription_infos}
    else
      _ -> :error
    end
  end

  defp map_route_type(subscriptions) do
    Enum.map(subscriptions, fn(subscription) ->
      {subscription, [%InformedEntity{route_type: 3}]}
    end)
  end

  defp map_routes([{sub, ie}], _params, route_id, direction_id) do
    route_entities = do_map_route(route_id, 3, direction_id)
    [{sub, ie ++ route_entities}]
  end
  defp map_routes([{sub1, ie1}, {sub2, ie2}], _params, route_id, 1) do
    route_entities_1 = do_map_route(route_id, 3, 1)
    route_entities_2 = do_map_route(route_id, 3, 0)

    [{sub1, ie1 ++ route_entities_1}, {sub2, ie2 ++ route_entities_2}]
  end
  defp map_routes([{sub1, ie1}, {sub2, ie2}], _params, route_id, 0) do
    route_entities_1 = do_map_route(route_id, 3, 0)
    route_entities_2 = do_map_route(route_id, 3, 1)

    [{sub1, ie1 ++ route_entities_1}, {sub2, ie2 ++ route_entities_2}]
  end

  defp do_map_route(route, type, direction_id) do
    [
      %InformedEntity{route: route, route_type: type},
      %InformedEntity{route: route, route_type: type, direction_id: direction_id}
    ]
  end

  defp extract_route_and_direction(route) do
    [name, direction] = String.split(route, " - ")
    route_id = String.replace_leading(name, "Route ", "")
    {route_id, String.to_integer(direction)}
  end
end
