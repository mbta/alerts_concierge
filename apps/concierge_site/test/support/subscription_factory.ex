defmodule ConciergeSite.SubscriptionFactory do
  @moduledoc """
  Standard interface for generating subscriptions
  """

  alias AlertProcessor.Model.{
    User,
    Subscription.RouteType,
  }
  alias AlertProcessor.Subscription.{
    SubwayMapper,
    BusMapper,
    CommuterRailMapper,
    FerryMapper,
    AccessibilityMapper,
    BikeStorageMapper,
    ParkingMapper,
  }

  def subscription(:subway = name, params) do
    params
    |> Map.put("route_type", RouteType.name_to_number(name))    
    |> SubwayMapper.map_subscriptions
    |> to_subscription
  end
  def subscription(:bus = name, params) do
    params
    |> Map.put("route_type", RouteType.name_to_number(name))
    |> BusMapper.map_subscription
    |> to_subscription
  end
  def subscription(:commuter_rail = name, params) do
    %{
      "trip_type" => "one_way",
      "return_end" => nil,
      "return_start" => nil,
    }
    |> Map.put("route_type", RouteType.name_to_number(name))    
    |> Map.merge(params)
    |> CommuterRailMapper.map_subscriptions()
    |> to_subscription
  end
  def subscription(:ferry = name, params) do
    %{"trip_type" => "one_way", "return_end" => nil, "return_start" => nil}
    |> Map.put("route_type", RouteType.name_to_number(name))    
    |> Map.merge(params)
    |> FerryMapper.map_subscriptions()
    |> to_subscription
  end
  def subscription(:bike, params) do
    params
    |> BikeStorageMapper.map_subscriptions
    |> to_subscription
  end
  def subscription(:parking, params) do
    params
    |> ParkingMapper.map_subscriptions
    |> to_subscription
  end
  def subscription(:accessibility, params) do
    params
    |> AccessibilityMapper.map_subscriptions
    |> to_subscription
  end

  defp to_subscription (response) do
    with {:ok, [{subscription, informed_entities} | _]} <- response do
      %{subscription | informed_entities: informed_entities, user: %User{}}
    end
  end
end
