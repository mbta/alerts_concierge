defmodule ConciergeSite.RouteHelper do
  @moduledoc """
  Render routes in templates
  """
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.{Route, Subscription}

  @doc """
  Get the name of a route, with a fallback name if the route isn't in the service info cache.

    iex> ConciergeSite.RouteHelper.route_name("Green")
    "Green Line"
    iex> ConciergeSite.RouteHelper.route_name("Green-B")
    "Green Line B"
    iex> ConciergeSite.RouteHelper.route_name(["Green-B", "Green-D"])
    "Green Line"
    iex> ConciergeSite.RouteHelper.route_name("CR-Worcester")
    "Framingham/Worcester Line"
    iex> ConciergeSite.RouteHelper.route_name("39")
    "Route 39"
    iex> ConciergeSite.RouteHelper.route_name("741")
    "Silver Line SL1"
    iex> ConciergeSite.RouteHelper.route_name("no-such-route")
    "Unknown Route"
  """
  @spec route_name(String.t()) :: String.t()
  def route_name(routes) when is_list(routes), do: "Green Line"
  def route_name("Green"), do: "Green Line"
  def route_name("Green-B"), do: "Green Line B"
  def route_name("Green-C"), do: "Green Line C"
  def route_name("Green-D"), do: "Green Line D"
  def route_name("Green-E"), do: "Green Line E"

  def route_name(route_id) do
    case ServiceInfoCache.get_route(route_id) do
      # We never want long names for buses
      {:ok, %{route_type: 3} = route} -> Route.bus_short_name(route)
      {:ok, route} -> Route.name(route)
      {:error, _} -> "Unknown Route"
    end
  end

  @doc """
  Get the name of a stop, with a fallback name if the stop isn't in the service info cache.

    iex> ConciergeSite.RouteHelper.stop_name("place-davis")
    "Davis"
    iex> ConciergeSite.RouteHelper.stop_name("does-not-exist")
    "Unknown Stop"
  """
  @spec stop_name(String.t()) :: String.t()
  def stop_name(stop_id) do
    case ServiceInfoCache.get_stop(stop_id) do
      {:ok, {name, _, _, _}} -> name
      {:ok, nil} -> "Unknown Stop"
    end
  end

  @spec collapse_duplicate_green_legs([Subscription.t()]) :: [Subscription.t()]
  def collapse_duplicate_green_legs(subscriptions) do
    Enum.reduce(subscriptions, [], fn subscription, unique_subscriptions ->
      case Enum.find_index(unique_subscriptions, fn %{origin: origin, destination: destination} ->
             subscription.route_type == 0 && origin == subscription.origin &&
               destination == subscription.destination
           end) do
        nil ->
          unique_subscriptions ++ [subscription]

        index ->
          List.update_at(unique_subscriptions, index, fn original_subscription ->
            %{
              original_subscription
              | route: add_route_to_subscription(original_subscription.route, subscription.route)
            }
          end)
      end
    end)
  end

  @spec add_route_to_subscription([String.t()] | String.t(), String.t()) :: [String.t()]
  defp add_route_to_subscription(original, additional) when is_list(original),
    do: original ++ [additional]

  defp add_route_to_subscription(original, additional), do: [original, additional]
end
