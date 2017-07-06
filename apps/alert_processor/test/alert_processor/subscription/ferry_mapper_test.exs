defmodule AlertProcessor.Subscription.FerryMapperTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{Model.InformedEntity, Model.Trip, Subscription.FerryMapper}

  describe "map_subscriptions one way" do
    @one_way_params %{
      "origin" => "Boat-Long",
      "destination" => "Boat-Hingham",
      "trips" => ["Boat-F1-OB-1805-WeekdaySummer", "Boat-F1-OB-2110-WeekdaySummer"],
      "relevant_days" => ["weekday"],
      "departure_start" => "12:00:00",
      "departure_end" => "14:00:00",
      "return_start" => nil,
      "return_end" => nil,
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "constructs subscription with severity" do
      {:ok, [{subscription, _ie}]} = FerryMapper.map_subscriptions(@one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = FerryMapper.map_subscriptions(@one_way_params)
      assert subscription.type == :ferry
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{subscription, _ie}]} = FerryMapper.map_subscriptions(@one_way_params)
      assert subscription.origin == "Long Wharf, Boston"
      assert subscription.destination == "Hewitt's Cove, Hingham"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{subscription, _ie}]} = FerryMapper.map_subscriptions(@one_way_params)
      assert subscription.start_time == ~T[16:00:00]
      assert subscription.end_time == ~T[18:00:00]
      assert subscription.relevant_days == [:weekday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "Boat-Long"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route in other direction" do
      reverse_trip_params = Map.merge(@one_way_params, %{"destination" => "Boat-Long", "origin" => "Boat-Hingham"})
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(reverse_trip_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 4}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      boat_long_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: "Boat-Long"}, informed_entity)
        end)
      assert boat_long_count == 1
      boat_hingham_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: "Boat-Hingham"}, informed_entity)
        end)
      assert boat_hingham_count == 1
      total_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 2
    end

    test "constructs subscription with trips" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      trip_1805_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-OB-1805-WeekdaySummer"}, informed_entity)
        end)
      assert trip_1805_count == 1
      trip_2110_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-OB-2110-WeekdaySummer"}, informed_entity)
        end)
      assert trip_2110_count == 1
      trip_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 2
    end
  end

  describe "map_subscriptions round trip" do
    @round_trip_params %{
      "origin" => "Boat-Long",
      "destination" => "Boat-Hingham",
      "trips" => ["Boat-F1-OB-1805-WeekdaySummer", "Boat-F1-OB-2110-WeekdaySummer"],
      "return_trips" => ["Boat-F1-IB-2100-WeekdaySummer"],
      "relevant_days" => ["weekday"],
      "departure_start" => "12:00:00",
      "departure_end" => "14:00:00",
      "return_start" => "18:00:00",
      "return_end" => "20:00:00",
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "constructs subscription with severity" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      assert sub1.alert_priority_type == :low
      assert sub2.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      assert sub1.type == :ferry
      assert sub2.type == :ferry
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      assert sub1.origin == "Long Wharf, Boston"
      assert sub1.destination == "Hewitt's Cove, Hingham"
      assert sub2.origin == "Hewitt's Cove, Hingham"
      assert sub2.destination == "Long Wharf, Boston"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      assert sub1.start_time == ~T[16:00:00]
      assert sub1.end_time == ~T[18:00:00]
      assert sub1.relevant_days == [:weekday]
      assert sub2.start_time == ~T[22:00:00]
      assert sub2.end_time == ~T[00:00:00]
      assert sub2.relevant_days == [:weekday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      amenity_informed_entities_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "Boat-Long"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
      amenity_informed_entities_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "Boat-Long"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      route_type_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 4}, informed_entity)
        end)
      assert route_type_entity_count == 1
      route_type_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 4}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      boat_hingham_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: "Boat-Hingham"}, informed_entity)
        end)
      assert boat_hingham_count == 1
      boat_long_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: "Boat-Long"}, informed_entity)
        end)
      assert boat_long_count == 1
      total_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 2
      boat_hingham_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: "Boat-Hingham"}, informed_entity)
        end)
      assert boat_hingham_count == 1
      boat_long_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: "Boat-Long"}, informed_entity)
        end)
      assert boat_long_count == 1
      total_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 2
    end

    test "constructs subscription with trips" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      trip_1805_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-OB-1805-WeekdaySummer"}, informed_entity)
        end)
      assert trip_1805_count == 1
      trip_2110_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-OB-2110-WeekdaySummer"}, informed_entity)
        end)
      assert trip_2110_count == 1
      trip_count =
        Enum.count(ie1, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 2

      trip_2100_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-IB-2100-WeekdaySummer"}, informed_entity)
        end)
      assert trip_2100_count == 1
      trip_count =
        Enum.count(ie2, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 1
    end
  end

  describe "map_trip_options" do
    @test_date Calendar.Date.from_ordinal!(2017, 187)

    test "returns inbound results for origin destination" do
      use_cassette "long_wharf_to_hingham_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = FerryMapper.map_trip_options("Boat-Long", "Boat-Hingham", :weekday, @test_date)
        assert [%Trip{arrival_time: ~T[09:55:00], departure_time: ~T[09:10:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-0910-WeekdaySummer"},
                %Trip{arrival_time: ~T[11:50:00], departure_time: ~T[11:00:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1100-WeekdaySummer"},
                %Trip{arrival_time: ~T[12:45:00], departure_time: ~T[12:15:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1215-WeekdaySummer"},
                %Trip{arrival_time: ~T[13:55:00], departure_time: ~T[13:00:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1300-WeekdaySummer"},
                %Trip{arrival_time: ~T[14:30:00], departure_time: ~T[14:00:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1400-WeekdaySummer"},
                %Trip{arrival_time: ~T[15:40:00], departure_time: ~T[14:40:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1440-WeekdaySummer"},
                %Trip{arrival_time: ~T[16:20:00], departure_time: ~T[15:40:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1540-WeekdaySummer"},
                %Trip{arrival_time: ~T[17:10:00], departure_time: ~T[16:30:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1630L-WeekdaySummer"},
                %Trip{arrival_time: ~T[18:50:00], departure_time: ~T[18:05:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1805-WeekdaySummer"},
                %Trip{arrival_time: ~T[19:25:00], departure_time: ~T[18:40:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1840-WeekdaySummer"},
                %Trip{arrival_time: ~T[20:20:00], departure_time: ~T[19:35:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-1935-WeekdaySummer"},
                %Trip{arrival_time: ~T[20:55:00], departure_time: ~T[20:15:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-2015-WeekdaySummer"},
                %Trip{arrival_time: ~T[22:05:00], departure_time: ~T[21:10:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-2110-WeekdaySummer"},
                %Trip{arrival_time: ~T[22:35:00], departure_time: ~T[21:50:00], destination: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, direction_id: 0, origin: {"Long Wharf, Boston", "Boat-Long"}, trip_number: "Boat-F1-OB-2150-WeekdaySummer"}] = trips
      end
    end

    test "returns outbound results for origin destination" do
      use_cassette "hingham_to_long_wharf_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = FerryMapper.map_trip_options("Boat-Hingham", "Boat-Long", :weekday, @test_date)
        assert [%Trip{arrival_time: ~T[06:23:00], departure_time: ~T[05:40:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-0540-WeekdaySummer"},
                %Trip{arrival_time: ~T[07:23:00], departure_time: ~T[06:40:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-0640-WeekdaySummer"},
                %Trip{arrival_time: ~T[11:00:00], departure_time: ~T[10:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1000-WeekdaySummer"},
                %Trip{arrival_time: ~T[12:55:00], departure_time: ~T[12:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1200-WeekdaySummer"},
                %Trip{arrival_time: ~T[13:50:00], departure_time: ~T[13:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1300-WeekdaySummer"},
                %Trip{arrival_time: ~T[14:35:00], departure_time: ~T[14:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1400-WeekdaySummer"},
                %Trip{arrival_time: ~T[15:33:00], departure_time: ~T[15:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1500-WeekdaySummer"},
                %Trip{arrival_time: ~T[16:27:00], departure_time: ~T[15:45:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1545-WeekdaySummer"},
                %Trip{arrival_time: ~T[17:12:00], departure_time: ~T[16:30:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1630-WeekdaySummer"},
                %Trip{arrival_time: ~T[17:57:00], departure_time: ~T[17:15:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1715-WeekdaySummer"},
                %Trip{arrival_time: ~T[19:28:00], departure_time: ~T[18:55:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1855-WeekdaySummer"},
                %Trip{arrival_time: ~T[20:12:00], departure_time: ~T[19:30:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1930-WeekdaySummer"},
                %Trip{arrival_time: ~T[21:03:00], departure_time: ~T[20:30:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-2030-WeekdaySummer"},
                %Trip{arrival_time: ~T[21:33:00], departure_time: ~T[21:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-2100-WeekdaySummer"}] = trips
      end
    end

    test "returns error for invalid origin destination combo" do
      assert :error = FerryMapper.map_trip_options("Boat-Charlestown", "Boat-Hingham", :weekday, @test_date)
    end

    test "returns saturday results" do
      use_cassette "hingham_to_long_wharf_saturday_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = FerryMapper.map_trip_options("Boat-Hingham", "Boat-Long", :saturday, @test_date)
        assert [%Trip{arrival_time: ~T[08:55:00], departure_time: ~T[08:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-0800-Weekend"},
                %Trip{arrival_time: ~T[09:55:00], departure_time: ~T[09:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-0900-Weekend"},
                %Trip{arrival_time: ~T[10:55:00], departure_time: ~T[10:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1000-Weekend"},
                %Trip{arrival_time: ~T[11:55:00], departure_time: ~T[11:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1100-Weekend"},
                %Trip{arrival_time: ~T[12:55:00], departure_time: ~T[12:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1200-Weekend"},
                %Trip{arrival_time: ~T[13:55:00], departure_time: ~T[13:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1300-Weekend"},
                %Trip{arrival_time: ~T[14:55:00], departure_time: ~T[14:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1400-Weekend"},
                %Trip{arrival_time: ~T[15:55:00], departure_time: ~T[15:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1500-Weekend"},
                %Trip{arrival_time: ~T[16:55:00], departure_time: ~T[16:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1600-Weekend"},
                %Trip{arrival_time: ~T[17:35:00], departure_time: ~T[17:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1700-Weekend"},
                %Trip{arrival_time: ~T[18:55:00], departure_time: ~T[18:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1800-Weekend"},
                %Trip{arrival_time: ~T[19:35:00], departure_time: ~T[19:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1900-Weekend"},
                %Trip{arrival_time: ~T[20:35:00], departure_time: ~T[20:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-2000-Weekend"},
                %Trip{arrival_time: ~T[21:45:00], departure_time: ~T[21:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-2100-Weekend"},
                %Trip{arrival_time: ~T[22:05:00], departure_time: ~T[21:30:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-2130-Saturday"},
                %Trip{arrival_time: ~T[23:10:00], departure_time: ~T[22:30:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-2230-Saturday"}] = trips
      end
    end

    test "returns sunday results" do
      use_cassette "hingham_to_long_wharf_sunday_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = FerryMapper.map_trip_options("Boat-Hingham", "Boat-Long", :sunday, @test_date)
        assert [%{arrival_time: ~T[08:55:00], departure_time: ~T[08:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-0800-Weekend"},
                %{arrival_time: ~T[09:55:00], departure_time: ~T[09:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-0900-Weekend"},
                %{arrival_time: ~T[10:55:00], departure_time: ~T[10:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1000-Weekend"},
                %{arrival_time: ~T[11:55:00], departure_time: ~T[11:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1100-Weekend"},
                %{arrival_time: ~T[12:55:00], departure_time: ~T[12:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1200-Weekend"},
                %{arrival_time: ~T[13:55:00], departure_time: ~T[13:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1300-Weekend"},
                %{arrival_time: ~T[14:55:00], departure_time: ~T[14:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1400-Weekend"},
                %{arrival_time: ~T[15:55:00], departure_time: ~T[15:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1500-Weekend"},
                %{arrival_time: ~T[16:55:00], departure_time: ~T[16:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1600-Weekend"},
                %{arrival_time: ~T[17:35:00], departure_time: ~T[17:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1700-Weekend"},
                %{arrival_time: ~T[18:55:00], departure_time: ~T[18:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1800-Weekend"},
                %{arrival_time: ~T[19:35:00], departure_time: ~T[19:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-1900-Weekend"},
                %{arrival_time: ~T[20:35:00], departure_time: ~T[20:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-2000-Weekend"},
                %{arrival_time: ~T[21:45:00], departure_time: ~T[21:00:00], destination: {"Long Wharf, Boston", "Boat-Long"}, direction_id: 1, origin: {"Hewitt's Cove, Hingham", "Boat-Hingham"}, trip_number: "Boat-F1-IB-2100-Weekend"}] = trips
      end
    end
  end
end
