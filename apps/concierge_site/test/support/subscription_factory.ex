defmodule ConciergeSite.SubscriptionFactory do
  @moduledoc """
  Standard interface for generating subscriptions
  """

  alias AlertProcessor.Model.User

  alias AlertProcessor.Subscription.{
    SubwayMapper,
    BusMapper,
    CommuterRailMapper,
    FerryMapper,
    AccessibilityMapper,
    BikeStorageMapper,
    ParkingMapper
  }

  def subscription(:subway, params) do
    SubwayMapper.map_subscriptions(params)
    |> to_subscription
  end

  def subscription(:bus, params) do
    BusMapper.map_subscription(params)
    |> to_subscription
  end

  def subscription(:commuter_rail, params) do
    %{"trip_type" => "one_way", "return_end" => nil, "return_start" => nil}
    |> Map.merge(params)
    |> CommuterRailMapper.map_subscriptions()
    |> to_subscription
  end

  def subscription(:ferry, params) do
    %{"trip_type" => "one_way", "return_end" => nil, "return_start" => nil}
    |> Map.merge(params)
    |> FerryMapper.map_subscriptions()
    |> to_subscription
  end

  def subscription(:bike, params) do
    BikeStorageMapper.map_subscriptions(params)
    |> to_subscription
  end

  def subscription(:parking, params) do
    ParkingMapper.map_subscriptions(params)
    |> to_subscription
  end

  def subscription(:accessibility, params) do
    AccessibilityMapper.map_subscriptions(params)
    |> to_subscription
  end

  defp to_subscription(response) do
    with {:ok, [{subscription, informed_entities} | _]} <- response do
      %{subscription | informed_entities: informed_entities, user: %User{}}
    end
  end
end
