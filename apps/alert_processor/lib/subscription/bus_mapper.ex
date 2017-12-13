defmodule AlertProcessor.Subscription.BusMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  bus into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  defdelegate build_subscription_transaction(subscriptions, user, originator), to: AlertProcessor.Subscription.Mapper

  @doc """
  map_subscription/1 receives a map of bus subscription params and returns
  arrays of subscription(s) and informed entities to creat in the database
  to be used for matching against alerts.
  """
  @spec map_subscription(map) :: {:ok, [Subscription.t], [InformedEntity.t]} | :error
  def map_subscription(%{"routes" => routes} = params) do
    params = Map.delete(params, "routes")
    subscription_infos = Enum.flat_map(routes, fn(route_and_direction) ->
      route_id = String.split_at(route_and_direction, -4) |> elem(0)
      direction = String.split_at(route_and_direction, -1) |> elem(1) |> String.to_integer
      {:ok, route} = ServiceInfoCache.get_route(route_id)

      params = params
      |> Map.put("route", route_id)
      |> Map.put("direction", direction)
      |> Map.put("origin", nil)
      |> Map.put("destination", nil)

      subscriptions = params
      |> create_subscriptions
      |> map_priority(params)
      |> map_type(:bus)

      map_entities(subscriptions, params, route)
    end)

    {:ok, subscription_infos}
  end

  defp map_entities(subscriptions, params, route) do
    subscriptions
    |> map_route_type(route)
    |> map_route(params, route)
    |> filter_duplicate_entities
  end
end
