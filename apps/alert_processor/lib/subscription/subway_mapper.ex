defmodule AlertProcessor.Subscription.SubwayMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  subway into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.{Route, Subscription}

  defdelegate build_subscription_transaction(subscriptions, user, originator),
    to: AlertProcessor.Subscription.Mapper

  @doc """
  map_subscription/1 receives a map of subway subscription params and returns
  arrays of subscription_info to create in the database
  to be used for matching against alerts.
  """
  @spec map_subscriptions(map) :: {:ok, [Subscription.subscription_info()]} | :error
  def map_subscriptions(%{"origin" => origin, "destination" => destination} = params) do
    route = get_route_by_stops(origin, destination)

    params =
      params
      |> Map.put("route", route.route_id)
      |> Map.put("direction", "")
      |> Map.put("return_trip", false)

    subscriptions =
      params
      |> create_subscriptions
      |> map_subscription_direction_id(route)
      |> map_type(:subway)

    {:ok, map_entities(subscriptions, params, route)}
  end

  defp map_entities(subscriptions, params, route) do
    subscriptions
    |> map_route_type(route)
    |> map_route(params, route)
    |> map_stops(params, route)
    |> filter_duplicate_entities
  end

  defp get_route_by_stops(origin, destination) do
    {:ok, subway_info} = ServiceInfoCache.get_subway_info()

    subway_info
    |> Enum.filter(fn %Route{stop_list: stop_list} ->
      List.keymember?(stop_list, origin, 1) && List.keymember?(stop_list, destination, 1)
    end)
    |> List.first()
  end
end
