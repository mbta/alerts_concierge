defmodule AlertProcessor.Subscription.SubwayMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  subway into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.{Route, Subscription}

  defdelegate build_subscription_transaction(subscriptions, user, originator_id), to: AlertProcessor.Subscription.Mapper

  @doc """
  map_subscription/1 receives a map of subway subscription params and returns
  arrays of subscription_info to create in the database
  to be used for matching against alerts.
  """
  @spec map_subscriptions(map) :: {:ok, [Subscription.subscription_info]} | :error
  def map_subscriptions(subscription_params) do
    with {:ok, subscriptions} <- map_timeframe(subscription_params),
         {:ok, subscriptions} <- map_priority(subscriptions, subscription_params),
         subscriptions <- map_type(subscriptions, :subway)
         do
      map_entities(subscriptions, subscription_params)
    else
      _ -> :error
    end
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
end
