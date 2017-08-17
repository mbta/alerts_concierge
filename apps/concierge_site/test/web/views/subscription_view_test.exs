defmodule ConciergeSite.SubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.SubscriptionView
  alias AlertProcessor.Model.{InformedEntity, Route, Subscription}
  import AlertProcessor.Factory

  describe "sorted_subscription/1" do
    test "sorted_subscriptions groups subscriptions by mode" do
      sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      sub2 = %Subscription{type: :bus, informed_entities: [%InformedEntity{route: "1", route_type: 3}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      sub4 = %Subscription{type: :bus, informed_entities: [%InformedEntity{route: "16", route_type: 3}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      assert %{amenity: [], ferry: [], bus: [^sub2, ^sub4], commuter_rail: [], subway: [^sub1, ^sub3]} = SubscriptionView.sorted_subscriptions([sub1, sub2, sub3, sub4])
    end

    test "sorted_subscriptions groups subscriptions by line" do
      sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      sub2 = %Subscription{origin: "Oak Grove", destination: "Downtown Crossing", type: :subway, informed_entities: [%InformedEntity{route: "Orange", route_type: 1}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      sub3 = %Subscription{origin: "Park Street", destination: "Davis", type: :subway, informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      sub4 = %Subscription{origin: "Revere Beach", destination: "Bowdoin", type: :subway, informed_entities: [%InformedEntity{route: "Blue", route_type: 1}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      sub5 = %Subscription{origin: "Packards Corner", destination: "Park Street", type: :subway, informed_entities: [%InformedEntity{route: "Green-B", route_type: 1}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      sub6 = %Subscription{origin: "Milton", destination: "Ashmont", type: :subway, informed_entities: [%InformedEntity{route: "Mattapan", route_type: 1}], relevant_days: [:weekday], start_time: ~T[12:00:00], end_time: ~T[14:00:00]}
      assert %{amenity: [], ferry: [], bus: [], commuter_rail: [], subway: [^sub1, ^sub3, ^sub6, ^sub2, ^sub5, ^sub4]} = SubscriptionView.sorted_subscriptions([sub1, sub2, sub3, sub4, sub5, sub6])
    end

    test "sorted_subscriptions sorts by earliest start_time" do
      sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, start_time: ~T[01:00:00], end_time: ~T[02:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
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

    test "sorted_subscriptions sorts when amenities with no routes present" do
      sub1 = %Subscription{origin: "Davis", destination: "Park Street", type: :subway, start_time: ~T[14:00:00], end_time: ~T[15:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:weekday]}
      sub2 = %Subscription{origin: "Davis", destination: "Harvard", type: :subway, start_time: ~T[12:00:00], end_time: ~T[13:00:00], informed_entities: [%InformedEntity{route: "Red", route_type: 1}], relevant_days: [:saturday, :sunday]}
      sub3 = %Subscription{type: :amenity, start_time: ~T[12:00:00], end_time: ~T[13:00:00], informed_entities: [%InformedEntity{stop: "place-nqncy", route_type: 4}], relevant_days: [:saturday, :sunday]}
      assert %{amenity: [^sub3], ferry: [], bus: [], commuter_rail: [], subway: [^sub1, ^sub2]} = SubscriptionView.sorted_subscriptions(Enum.shuffle([sub1, sub2, sub3]))
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

  describe "vacation_color_class/2" do
    test "class when alerts are paused" do
      assert IO.iodata_to_binary(SubscriptionView.vacation_color_class(~N[2017-07-10 00:00:00], ~N[2117-07-10 00:00:00])) == "callout-active"
    end

    test "class when alerts are not paused" do
      assert IO.iodata_to_binary(SubscriptionView.vacation_color_class(nil, nil)) == "callout-inactive"
    end
  end

  describe "vacation_banner_content/2" do
    test "message when alerts are paused" do
      assert IO.iodata_to_binary(SubscriptionView.vacation_banner_content(~N[2017-07-10 00:00:00], ~N[2117-07-10 00:00:00])) == "Your alerts have been paused until July 10, 2117."
    end

    test "message when alerts are not paused" do
      assert IO.iodata_to_binary(SubscriptionView.vacation_banner_content(nil, nil)) == "Don't need updates right now?"
    end
  end

  describe "on_vacation?/2" do
    test "returns true if now is later than vacation start and before vacation end" do
      assert SubscriptionView.on_vacation?(~N[2010-07-10 00:00:00], ~N[2200-07-10 00:00:00])
    end

    test "returns false if vacation_end is in the past" do
      refute SubscriptionView.on_vacation?(~N[2017-04-01 00:00:00], ~N[2017-05-01 00:00:00])
    end

    test "returns false if vacation_start is in the future" do
      refute SubscriptionView.on_vacation?(~N[2217-04-01 00:00:00], ~N[2217-05-01 00:00:00])
    end

    test "returns false if either value is nil" do
      refute SubscriptionView.on_vacation?(nil, ~N[2035-07-01 00:00:00])
      refute SubscriptionView.on_vacation?(~N[2035-07-01 00:00:00], nil)
    end
  end
end
