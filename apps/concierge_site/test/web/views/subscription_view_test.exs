defmodule ConciergeSite.SubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.SubscriptionView
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  test "sorted_subscriptions groups subscriptions by mode" do
    sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}]}
    sub2 = %Subscription{type: :bus, informed_entities: [%InformedEntity{route: "1", route_type: 3}]}
    sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}]}
    sub4 = %Subscription{type: :bus, informed_entities: [%InformedEntity{route: "16", route_type: 3}]}
    assert %{amenity: [], boat: [], bus: [^sub2, ^sub4], commuter_rail: [], subway: [^sub1, ^sub3]} = SubscriptionView.sorted_subscriptions([sub1, sub2, sub3, sub4])
  end

  test "sorted_subscriptions groups subscriptions by line" do
    sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}]}
    sub2 = %Subscription{origin: "Oak Grove", destination: "Downtown Crossing", type: :subway, informed_entities: [%InformedEntity{route: "Orange", route_type: 1}]}
    sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}]}
    assert %{amenity: [], boat: [], bus: [], commuter_rail: [], subway: [^sub2, ^sub1, ^sub3]} = SubscriptionView.sorted_subscriptions([sub1, sub2, sub3])
  end

  test "sorted_subscriptions sorts by earliest start_time" do
    sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, start_time: ~T[14:00:00], end_time: ~T[15:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}]}
    sub2 = %Subscription{origin: "Davis", destination: "Harvard", type: :subway, start_time: ~T[12:00:00], end_time: ~T[13:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}]}
    sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, start_time: ~T[10:00:00], end_time: ~T[11:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}]}
    assert %{amenity: [], boat: [], bus: [], commuter_rail: [], subway: [^sub3, ^sub2, ^sub1]} = SubscriptionView.sorted_subscriptions([sub1, sub2, sub3])
  end
end
