defmodule AlertProcessor.InformedEntityFilterTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  alias AlertProcessor.InformedEntityFilter
  import AlertProcessor.Factory

  describe "subscription_match?/2" do
    test "returns true for trip match per subscription start time." do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "place-DB-2205",
        destination: "place-DB-2265",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00]
      ]

      subscription = build(:subscription, subscription_details)

      scheduled_origin_event = %{
        stop_id: "place-DB-2205",
        departure_time: "2018-04-02T08:00:00-04:00"
      }

      scheduled_destination_event = %{
        stop_id: "place-DB-2265",
        departure_time: nil
      }

      schedule = [scheduled_origin_event, scheduled_destination_event]

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: schedule,
        trip: "767"
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false for trip mismatch per subscription start time" do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "place-DB-2205",
        destination: "place-DB-2265",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00]
      ]

      subscription = build(:subscription, subscription_details)

      scheduled_origin_event = %{
        stop_id: "place-DB-2205",
        departure_time: "2018-04-02T07:45:00-04:00"
      }

      scheduled_destination_event = %{
        stop_id: "place-DB-2265",
        departure_time: nil
      }

      schedule = [scheduled_origin_event, scheduled_destination_event]

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: schedule,
        trip: "767"
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false for trip match per subscription end time" do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "place-DB-2205",
        destination: "place-DB-2265",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[08:05:00]
      ]

      subscription = build(:subscription, subscription_details)

      scheduled_origin_event = %{
        stop_id: "place-DB-2205",
        departure_time: "2018-04-02T08:10:00-04:00"
      }

      scheduled_destination_event = %{
        stop_id: "place-DB-2265",
        departure_time: nil
      }

      schedule = [scheduled_origin_event, scheduled_destination_event]

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: schedule,
        trip: "767"
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true for trip match per travel start time." do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "place-DB-2205",
        destination: "place-DB-2265",
        facility_types: [],
        start_time: ~T[07:00:00],
        end_time: ~T[09:00:00],
        travel_start_time: ~T[08:00:00],
        travel_end_time: ~T[08:05:00]
      ]

      subscription = build(:subscription, subscription_details)

      scheduled_origin_event = %{
        stop_id: "place-DB-2205",
        departure_time: "2018-04-02T08:00:00-04:00"
      }

      scheduled_destination_event = %{
        stop_id: "place-DB-2265",
        departure_time: nil
      }

      schedule = [scheduled_origin_event, scheduled_destination_event]

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: schedule,
        trip: "767"
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false for trip mismatch per travel start time" do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "place-DB-2205",
        destination: "place-DB-2265",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        travel_start_time: ~T[08:05:00],
        travel_end_time: ~T[08:10:00]
      ]

      subscription = build(:subscription, subscription_details)

      scheduled_origin_event = %{
        stop_id: "place-DB-2205",
        departure_time: "2018-04-02T08:00:00-04:00"
      }

      scheduled_destination_event = %{
        stop_id: "place-DB-2265",
        departure_time: nil
      }

      schedule = [scheduled_origin_event, scheduled_destination_event]

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: schedule,
        trip: "767"
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false for trip match per travel end time" do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "place-DB-2205",
        destination: "place-DB-2265",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        travel_start_time: ~T[08:00:00],
        travel_end_time: ~T[08:05:00]
      ]

      subscription = build(:subscription, subscription_details)

      scheduled_origin_event = %{
        stop_id: "place-DB-2205",
        departure_time: "2018-04-02T08:10:00-04:00"
      }

      scheduled_destination_event = %{
        stop_id: "place-DB-2265",
        departure_time: nil
      }

      schedule = [scheduled_origin_event, scheduled_destination_event]

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: schedule,
        trip: "767"
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false for trip mismatch if schedule missing event for origin" do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "place-DB-2205",
        destination: "place-DB-2265",
        facility_types: [],
        start_time: ~T[08:00:00]
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: [],
        trip: "767"
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false for trip mismatch if nil schedule and trip given" do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "place-DB-2205",
        destination: "place-DB-2265",
        facility_types: [],
        start_time: ~T[08:00:00]
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: nil,
        trip: "767"
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true with route type match" do
      route_type = 1

      subscription_details = [
        route_type: route_type,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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

    test "returns true with stop match (stop in between origin and destination)" do
      # As you can see here:
      # https://cdn.mbta.com/sites/default/files/maps/2018-04-map-rapid-transit-key-bus-v31a.pdf,
      # "Back Bay" (place-bbsta) is in between "Stony Brook" (place-sbmnl) and "Assembly" (place-astao).
      subscription_details_1 = [
        route_type: 1,
        direction_id: 0,
        route: "Orange",
        origin: "place-sbmnl",
        destination: "place-astao",
        facility_types: []
      ]

      subscription_1 = build(:subscription, subscription_details_1)

      informed_entity_details_1 = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "place-bbsta",
        activities: ["RIDE"]
      ]

      informed_entity_1 = build(:informed_entity, informed_entity_details_1)
      assert InformedEntityFilter.subscription_match?(subscription_1, informed_entity_1)

      # The scenario below is the return trip for the scenario above (opposite origin/destination).
      subscription_details_2 = [
        route_type: 1,
        direction_id: 1,
        route: "Orange",
        origin: "place-astao",
        destination: "place-sbmnl",
        facility_types: []
      ]

      subscription_2 = build(:subscription, subscription_details_2)

      informed_entity_details_2 = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "place-bbsta",
        activities: ["RIDE"]
      ]

      informed_entity_2 = build(:informed_entity, informed_entity_details_2)
      assert InformedEntityFilter.subscription_match?(subscription_2, informed_entity_2)
    end

    test "returns true with stop match ('in between' stop on Red line's Ashmont branch/shape)" do
      # As you can see here:
      # https://cdn.mbta.com/sites/default/files/maps/2018-04-map-rapid-transit-key-bus-v31a.pdf,
      # "Shawmut" (place-smmnl) is in between "Alewife" (place-alfcl) and "Ashmont" (place-asmnl).
      subscription_details_1 = [
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-alfcl",
        destination: "place-asmnl",
        facility_types: []
      ]

      subscription_1 = build(:subscription, subscription_details_1)

      informed_entity_details_1 = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "place-smmnl",
        activities: ["RIDE"]
      ]

      informed_entity_1 = build(:informed_entity, informed_entity_details_1)
      assert InformedEntityFilter.subscription_match?(subscription_1, informed_entity_1)
    end

    test "returns true with stop match ('in between' stop on Red line's Braintree branch/shape)" do
      # As you can see here:
      # https://cdn.mbta.com/sites/default/files/maps/2018-04-map-rapid-transit-key-bus-v31a.pdf,
      # "Quincy Adams" (place-qamnl) is in between "Alewife" (place-alfcl) and "Braintree" (place-brntn).
      subscription_details_1 = [
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-alfcl",
        destination: "place-brntn",
        facility_types: []
      ]

      subscription_1 = build(:subscription, subscription_details_1)

      informed_entity_details_1 = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "place-qamnl",
        activities: ["RIDE"]
      ]

      informed_entity_1 = build(:informed_entity, informed_entity_details_1)
      assert InformedEntityFilter.subscription_match?(subscription_1, informed_entity_1)
    end

    test "returns true with stop match (without stop but stops in schedule)" do
      subscription_details = [
        route_type: 2,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: []
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: 2,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: ["BOARD", "EXIT"],
        schedule: [%{stop_id: "some origin"}, %{stop_id: "some destination"}]
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
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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

    test "returns false with stop mismatch (without stop, origin and destination not in schedule)" do
      subscription_details = [
        route_type: 2,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some stop",
        facility_types: []
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: 2,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: [%{stop_id: "some other stop"}]
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with stop mismatch (without stop, origin in schedule, destination not in schedule)" do
      # If no stop is provided by the alert/informed_entity, origin and
      # destination must both be part of the schedule for the subscription to match.
      subscription_details = [
        route_type: 2,
        direction_id: 0,
        route: "some route",
        origin: "some origin",
        destination: "some destination",
        facility_types: []
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: 2,
        direction_id: nil,
        route: nil,
        stop: nil,
        activities: nil,
        schedule: [%{stop_id: "some origin"}]
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with stop mismatch (with stop not in between origin and destination)" do
      # As you can see here:
      # https://cdn.mbta.com/sites/default/files/maps/2018-04-map-rapid-transit-key-bus-v31a.pdf,
      # "Harvard" (place-harsq) is not in between "Alewife" (place-alfcl) and
      # "Porter" (place-portr).
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-alfcl",
        destination: "place-portr",
        facility_types: []
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "place-harsq",
        activities: ["RIDE"]
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      refute InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns false with stop match (with stop in between origin and destination but wrong activity)" do
      # As you can see here:
      # https://cdn.mbta.com/sites/default/files/maps/2018-04-map-rapid-transit-key-bus-v31a.pdf,
      # "Davis" (place-davis) is in between "Alewife" (place-alfcl) and "Porter" (place-portr).
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "Alewife",
        destination: "Porter",
        facility_types: []
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: "Davis",
        activities: ["BOARD"]
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
        facility_types: []
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
        facility_types: []
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

    test "returns true with activities match (RIDE)" do
      # An "activities RIDE match" happens when the alert's informed_entity
      # activities includes "RIDE" and it's stop equals the subscription's
      # origin or destination value. It can also happen if the
      # informed_entity's stop is nil.
      stop = "some stop"

      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "some route",
        origin: stop,
        destination: "some destination",
        facility_types: []
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        stop: stop,
        activities: ["RIDE"]
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
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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
        facility_types: []
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
        facility_types: [:elevator]
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
        facility_types: [:escalator]
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
        facility_types: [:parking_area]
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
        facility_types: [:bike_storage]
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
        origin: nil,
        destination: nil,
        facility_types: [:elevator],
        type: :accessibility
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
        type: :accessibility
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
        facility_types: [:bike_storage]
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
        facility_types: [:bike_storage]
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
        type: :accessibility
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
        facility_types: [:bike_storage]
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
        facility_types: [:escalator]
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
        origin: "some stop",
        destination: "some stop",
        facility_types: [:elevator]
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

    test "returns false with a 'stop subscription' (activities: ['RIDE'] with different stop)" do
      subscription_details = [
        route_type: nil,
        direction_id: nil,
        route: nil,
        origin: "some stop",
        destination: "some stop",
        facility_types: [:elevator]
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: 1,
        direction_id: nil,
        route: nil,
        stop: "some other stop",
        activities: ["RIDE"]
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
        origin: nil,
        destination: nil,
        facility_types: [:elevator],
        type: :accessibility
      ]

      subscription = build(:subscription, subscription_details)

      informed_entity_details = [
        route_type: 1,
        direction_id: nil,
        route: nil,
        stop: "place-harsq",
        activities: ["USING_WHEELCHAIR"]
      ]

      informed_entity = build(:informed_entity, informed_entity_details)
      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end

    test "returns true for admin subscription match" do
      subscription = build(:subscription, route_type: 2, is_admin: true)

      informed_entity =
        build(
          :informed_entity,
          route_type: 2,
          direction_id: nil,
          route: "CR-Fitchburg",
          stop: "place-portr",
          activities: ["BOARD"]
        )

      assert InformedEntityFilter.subscription_match?(subscription, informed_entity)
    end
  end
end
