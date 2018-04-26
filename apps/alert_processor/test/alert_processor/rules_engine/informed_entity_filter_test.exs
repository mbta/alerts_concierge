defmodule AlertProcessor.InformedEntityFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.InformedEntityFilter
  import AlertProcessor.Factory

  describe "subscription_match?/2" do
    test "returns true with route type match" do
      route_type =  1
      subscription_details = [
        route_type: route_type,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: route_type,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with route type mismatch" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: 2,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with direction_id match" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: 0,
        route: nil,
        stop: nil,
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with direction_id mismatch" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: 1,
        route: nil,
        stop: nil,
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with route match" do
      route = "some route"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: route,
        origin: "some origin",
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: route,
        stop: nil,
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with route mismatch" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: "some other route",
        stop: nil,
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with stop match (on origin)" do
      stop = "some stop"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: stop,
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with stop match (on destination)" do
      stop = "some stop"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: stop,
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with stop mismatch" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "some stop that is not origin or destination",
        activities: nil
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

   test "returns false with stop mismatch (bus subscription and BOARD activity)" do
      # Bus subscriptions don't have an origin and destination
      subscription_details = [
        route_type: 3,
        direction_id: 0,
        route: "some route",
        origin: nil,
        destination: nil,
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "some stop",
        activities: ["BOARD"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with stop mismatch (bus subscription and EXIT activity)" do
      # Bus subscriptions don't have an origin and destination
      subscription_details = [
        route_type: 3,
        direction_id: 0,
        route: "some route",
        origin: nil,
        destination: nil,
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "some stop",
        activities: ["EXIT"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with activities match (BOARD)" do
      # An "activities BOARD match" happens when the alert's informed_entity
      # activities includes "BOARD" and it's stop equals the subscription's
      # origin value. It can also happen if the informed_entity's stop is nil.
      stop = "some stop"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: stop,
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: ["BOARD"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with activities match (BOARD) and informed_entity stop of nil" do
      # An "activities BOARD match" happens when the alert's informed_entity
      # activities includes "BOARD" and it's stop equals the subscription's
      # origin value. It can also happen if the informed_entity's stop is nil.
      stop = "some stop"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: stop,
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: ["BOARD"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with activities mismatch (BOARD)" do
      # Note that the `informed_entity_details` below has "BOARD" in it's
      # activities but the stop match is on the subscription's destination.
      # This is not an activities match because users "EXIT" at destinations.
      stop = "some stop"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: stop,
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: ["BOARD"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with activities match (EXIT)" do
      # An "activities EXIT match" happens when the alert's informed_entity
      # activities includes "EXIT" and it's stop equals the subscription's
      # destination value.
      stop = "some stop"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: stop,
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: ["EXIT"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with activities match (EXIT) and informed_entity stop of nil" do
      # An "activities EXIT match" happens when the alert's informed_entity
      # activities includes "EXIT" and it's stop equals the subscription's
      # destination value. It can also happen if the informed_entity's stop is nil.
      stop = "some stop"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: stop,
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: ["EXIT"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with activities mismatch (EXIT)" do
      # Note that the `informed_entity_details` below has "EXIT" in it's
      # activities but the stop match is on the subscription's origin.
      # This is not an activities match because users "BOARD" at origins.
      stop = "some stop"
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: stop,
        destination: "some destination",
        facility_types: [],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: ["EXIT"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with activities match (USING_WHEELCHAIR)" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [:elevator],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: ["USING_WHEELCHAIR"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with activities match (USING_ESCALATOR)" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [:escalator],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: ["USING_ESCALATOR"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with activities match (PARK_CAR)" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [:parking_area],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: ["PARK_CAR"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with activities match (STORE_BIKE)" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: [:bike_storage],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: ["STORE_BIKE"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with activities mismatch (accessibility subscription and BOARD) " do
      # Accessibility subscription should not match for BOARD activities.
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: "some route",
        origin:  nil,
        destination: nil,
        facility_types: [:elevator],
        type: "accessibility"
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: "some route",
        stop: nil,
        activities: ["BOARD"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with activities mismatch (accessibility subscription and EXIT) " do
      # Accessibility subscription should not match for BOARD activities.
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: "some route",
        origin: nil,
        destination: nil,
        facility_types: [:elevator],
        type: "accessibility"
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: "some route",
        stop: nil,
        activities: ["EXIT"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with a 'stop subscription' (activities match)" do
      # A "stop subscription" has these characteristics:
      #   * route_type, direction_id, and route are set to nil
      #   * origin and it's destination are equal
      #
      # Note that `informed_entity_details` below has non-nil values for
      # route_type, direction_id, and route. This is important to have coverage
      # for scenarios in which the subscription has nil values for these fields
      # but the alert's informed_entity doesn't.
      #
      stop = "some stop"
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: stop,
        destination: stop,
        facility_types: [:bike_storage],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        stop: stop,
        activities: ["STORE_BIKE"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with a 'stop subscription' (activities mismatch)" do
      # A "stop subscription" has these characteristics:
      #   * route_type, direction_id, and route are set to nil
      #   * origin and it's destination are equal
      #
      stop = "some stop"
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: stop,
        destination: stop,
        facility_types: [:bike_storage],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: ["USING_ESCALATOR"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with a 'stop subscription' (activities: ['BOARD'])" do
      # A "stop subscription" has these characteristics:
      #   * route_type, direction_id, and route are set to nil
      #   * origin and it's destination are equal
      #
      stop = "some stop"
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: stop,
        destination: stop,
        facility_types: [:bike_storage],
        type: "accessibility"
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: ["BOARD"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with a 'stop subscription' (activities: ['EXIT'])" do
      # A "stop subscription" has these characteristics:
      #   * route_type, direction_id, and route are set to nil
      #   * origin and it's destination are equal
      #
      stop = "some stop"
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: stop,
        destination: stop,
        facility_types: [:bike_storage],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: ["EXIT"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with a 'stop subscription' (stop mismatch)" do
      # A "stop subscription" has these characteristics:
      #   * route_type, direction_id, and route are set to nil
      #   * origin and it's destination are equal
      #
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "some stop",
        destination: "some stop",
        facility_types: [:escalator],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "some other stop",
        activities: ["USING_ESCALATOR"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with a 'stop subscription' and nil informed_entity stop" do
      # A "stop subscription" has these characteristics:
      #   * route_type, direction_id, and route are set to nil
      #   * origin and it's destination are equal
      #
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin:  "some stop",
        destination: "some stop",
        facility_types: [:elevator],
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: 1,
        direction_id: nil,
        route: "some route",
        stop: nil,
        activities: ["USING_WHEELCHAIR"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true for accessibility subscription route-stop match" do
      # With an "accessibility" type subscription with no origin or destination
      # we want to infer the stops from the route. In the scenario below the
      # "Harvard" stop is on the "Red" line so we have a match.
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: "Red",
        origin:  nil,
        destination: nil,
        facility_types: [:elevator],
        type: "accessibility"
      ]
      subscription = build(:subscription, subscription_details)
      informed_entity_details = [
        route_type: 1,
        direction_id: nil,
        route: nil,
        stop: "Harvard",
        activities: ["USING_WHEELCHAIR"]
      ]
      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end
  end
end
