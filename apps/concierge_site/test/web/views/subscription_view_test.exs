defmodule ConciergeSite.SubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.SubscriptionView
  alias AlertProcessor.Model.{InformedEntity, Route, Subscription}
  import AlertProcessor.Factory

  describe "sorted_subscription/1" do
    test "sorted_subscriptions groups subscriptions by mode" do
      sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      sub2 = %Subscription{type: :bus, informed_entities: [%InformedEntity{route: "1", route_type: 3}], relevant_days: [:weekday]}
      sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      sub4 = %Subscription{type: :bus, informed_entities: [%InformedEntity{route: "16", route_type: 3}], relevant_days: [:weekday]}
      assert %{amenity: [], ferry: [], bus: [^sub2, ^sub4], commuter_rail: [], subway: [^sub1, ^sub3]} = SubscriptionView.sorted_subscriptions([sub1, sub2, sub3, sub4])
    end

    test "sorted_subscriptions groups subscriptions by line" do
      sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      sub2 = %Subscription{origin: "Oak Grove", destination: "Downtown Crossing", type: :subway, informed_entities: [%InformedEntity{route: "Orange", route_type: 1}], relevant_days: [:weekday]}
      sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      sub4 = %Subscription{origin: "Revere Beach", destination: "Bowdoin", type: :subway, informed_entities: [%InformedEntity{route: "Blue", route_type: 1}], relevant_days: [:weekday]}
      sub5 = %Subscription{origin: "Packards Corner", destination: "Park Street", type: :subway, informed_entities: [%InformedEntity{route: "Green-B", route_type: 1}], relevant_days: [:weekday]}
      sub6 = %Subscription{origin: "Milton", destination: "Ashmont", type: :subway, informed_entities: [%InformedEntity{route: "Mattapan", route_type: 1}], relevant_days: [:weekday]}
      assert %{amenity: [], ferry: [], bus: [], commuter_rail: [], subway: [^sub1, ^sub3, ^sub6, ^sub2, ^sub5, ^sub4]} = SubscriptionView.sorted_subscriptions([sub1, sub2, sub3, sub4, sub5, sub6])
    end

    test "sorted_subscriptions sorts by earliest start_time" do
      sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, start_time: ~T[14:00:00], end_time: ~T[15:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      sub2 = %Subscription{origin: "Davis", destination: "Harvard", type: :subway, start_time: ~T[12:00:00], end_time: ~T[13:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, start_time: ~T[10:00:00], end_time: ~T[11:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      assert %{amenity: [], ferry: [], bus: [], commuter_rail: [], subway: [^sub3, ^sub2, ^sub1]} = SubscriptionView.sorted_subscriptions([sub1, sub2, sub3])
    end

    test "sorted_subscriptions sorts by relevant days" do
      sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, start_time: ~T[14:00:00], end_time: ~T[15:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      sub2 = %Subscription{origin: "Davis", destination: "Harvard", type: :subway, start_time: ~T[12:00:00], end_time: ~T[13:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:saturday, :sunday]}
      sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, start_time: ~T[10:00:00], end_time: ~T[11:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:sunday]}
      sub4 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, start_time: ~T[14:00:00], end_time: ~T[15:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday, :sunday, :saturday]}
      sub5 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, start_time: ~T[14:00:00], end_time: ~T[15:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday, :saturday]}
      sub6 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, start_time: ~T[14:00:00], end_time: ~T[15:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday, :sunday]}
      assert %{amenity: [], ferry: [], bus: [], commuter_rail: [], subway: [^sub4, ^sub5, ^sub6, ^sub1, ^sub2, ^sub3]} = SubscriptionView.sorted_subscriptions(Enum.shuffle([sub1, sub2, sub3, sub4, sub5, sub6]))
    end
  end

  describe "parse_route/1" do
    test "returns the route for a given subscription" do
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.put(:informed_entities, bus_subscription_entities())

      assert %Route{route_id: "57A"} = SubscriptionView.parse_route(subscription)
    end
  end
end
