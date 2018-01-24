defmodule ConciergeSite.SubscriptionFactory do
  @moduledoc """
  Standard interface for generating subscriptions
  """

  alias AlertProcessor.Subscription.SubwayMapper
  alias AlertProcessor.Subscription.BusMapper
  alias AlertProcessor.Subscription.CommuterRailMapper
  alias AlertProcessor.Subscription.FerryMapper
  alias AlertProcessor.Model.User

  def subscription(:subway, params) do
    SubwayMapper.map_subscriptions(params)
    |> to_subscriptions
  end
  def subscription(:bus, params) do
    BusMapper.map_subscription(params)
    |> to_subscriptions
  end
  def subscription(:commuter_rail, params) do
    %{"trip_type" => "one_way", "return_end" => nil, "return_start" => nil}
    |> Map.merge(params)
    |> CommuterRailMapper.map_subscriptions()
    |> to_subscriptions
  end
  def subscription(:ferry, params) do
    %{"trip_type" => "one_way", "return_end" => nil, "return_start" => nil}
    |> Map.merge(params)
    |> FerryMapper.map_subscriptions()
    |> to_subscriptions
  end

  defp to_subscriptions (response) do
    with {:ok, subscriptions_and_informed_entities} <- response do
      subscriptions_and_informed_entities
      |> Enum.map(fn {subscription, informed_entities} ->
        %{subscription | informed_entities: informed_entities, user: %User{}}
      end)
    end
  end
end
