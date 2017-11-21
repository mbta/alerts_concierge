defmodule AlertProcessor.Subscription.CommuterRailMapperTest do
  use AlertProcessor.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import AlertProcessor.Factory
  alias AlertProcessor.{Model.InformedEntity, Model.Trip, Subscription.CommuterRailMapper}

  describe "map_subscriptions one way" do
    @one_way_params %{
      "origin" => "Anderson/ Woburn",
      "destination" => "place-north",
      "trips" => ["123", "125"],
      "relevant_days" => ["saturday"],
      "departure_start" => ~T[12:00:00],
      "departure_end" => ~T[14:00:00],
      "return_start" => nil,
      "return_end" => nil,
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "constructs subscription with severity" do
      {:ok, [{subscription, _ie}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      assert subscription.type == :commuter_rail
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{subscription, _ie}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      assert subscription.origin == "Anderson/ Woburn"
      assert subscription.destination == "place-north"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{subscription, _ie}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      assert subscription.start_time == ~T[12:00:00]
      assert subscription.end_time == ~T[14:00:00]
      assert subscription.relevant_days == [:saturday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub, informed_entities}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "Anderson/ Woburn"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, [{_sub, informed_entities}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route in other direction" do
      reverse_trip_params = Map.merge(@one_way_params, %{"destination" => "Anderson/ Woburn", "origin" => "place-north"})
      {:ok, [{_sub, informed_entities}]} = CommuterRailMapper.map_subscriptions(reverse_trip_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub, informed_entities}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 2}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub, informed_entities}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      north_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "place-north", direction_id: nil}, informed_entity)
        end)
      assert north_station_count == 1
      mishawum_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Mishawum", direction_id: nil}, informed_entity)
        end)
      assert mishawum_station_count == 1
      winchester_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Winchester Center", direction_id: nil}, informed_entity)
        end)
      assert winchester_station_count == 1
      wedgemere_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Wedgemere", direction_id: nil}, informed_entity)
        end)
      assert wedgemere_station_count == 1
      west_medford_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "West Medford", direction_id: nil}, informed_entity)
        end)
      assert west_medford_station_count == 1
      anderson_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Anderson/ Woburn", direction_id: nil}, informed_entity)
        end)
      assert anderson_station_count == 1
      north_station_with_direction_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "place-north", direction_id: 1}, informed_entity)
        end)
      assert north_station_with_direction_count == 1
      mishawum_station_with_direction_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Mishawum", direction_id: 1}, informed_entity)
        end)
      assert mishawum_station_with_direction_count == 1
      winchester_station_with_direction_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Winchester Center", direction_id: 1}, informed_entity)
        end)
      assert winchester_station_with_direction_count == 1
      wedgemere_station_with_direction_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Wedgemere", direction_id: 1}, informed_entity)
        end)
      assert wedgemere_station_with_direction_count == 1
      west_medford_station_with_direction_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "West Medford", direction_id: 1}, informed_entity)
        end)
      assert west_medford_station_with_direction_count == 1
      anderson_station_with_direction_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Anderson/ Woburn", direction_id: 1}, informed_entity)
        end)
      assert anderson_station_with_direction_count == 1
      total_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 12
    end

    test "constructs subscription with trips" do
      {:ok, [{_sub, informed_entities}]} = CommuterRailMapper.map_subscriptions(@one_way_params)
      trip_123_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{trip: "123"}, informed_entity)
        end)
      assert trip_123_count == 1
      trip_125_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{trip: "125"}, informed_entity)
        end)
      assert trip_125_count == 1
      trip_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 2
    end
  end

  describe "map_subscriptions round trip" do
    @round_trip_params %{
      "origin" => "place-north",
      "destination" => "Anderson/ Woburn",
      "trips" => ["123", "125"],
      "return_trips" => ["588", "590"],
      "relevant_days" => ["weekday"],
      "departure_start" => ~T[12:00:00],
      "departure_end" => ~T[14:00:00],
      "return_start" => ~T[18:00:00],
      "return_end" => ~T[20:00:00],
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "constructs subscription with severity" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      assert sub1.alert_priority_type == :low
      assert sub2.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      assert sub1.type == :commuter_rail
      assert sub2.type == :commuter_rail
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      assert sub1.origin == "place-north"
      assert sub1.destination == "Anderson/ Woburn"
      assert sub2.origin == "Anderson/ Woburn"
      assert sub2.destination == "place-north"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      assert sub1.start_time == ~T[12:00:00]
      assert sub1.end_time == ~T[14:00:00]
      assert sub1.relevant_days == [:weekday]
      assert sub2.start_time == ~T[18:00:00]
      assert sub2.end_time == ~T[20:00:00]
      assert sub2.relevant_days == [:weekday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      amenity_informed_entities_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-north"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
      amenity_informed_entities_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-north"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      route_type_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 2}, informed_entity)
        end)
      assert route_type_entity_count == 1
      route_type_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 2}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      anderson_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Anderson/ Woburn", direction_id: nil}, informed_entity)
        end)
      assert anderson_station_count == 1
      mishawum_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Mishawum", direction_id: nil}, informed_entity)
        end)
      assert mishawum_station_count == 1
      winchester_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Winchester Center", direction_id: nil}, informed_entity)
        end)
      assert winchester_station_count == 1
      wedgemere_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Wedgemere", direction_id: nil}, informed_entity)
        end)
      assert wedgemere_station_count == 1
      west_medford_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "West Medford", direction_id: nil}, informed_entity)
        end)
      assert west_medford_station_count == 1
      north_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "place-north", direction_id: nil}, informed_entity)
        end)
      assert north_station_count == 1
      anderson_station_with_direction_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Anderson/ Woburn", direction_id: 0}, informed_entity)
        end)
      assert anderson_station_with_direction_count == 1
      mishawum_station_with_direction_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Mishawum", direction_id: 0}, informed_entity)
        end)
      assert mishawum_station_with_direction_count == 1
      winchester_station_with_direction_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Winchester Center", direction_id: 0}, informed_entity)
        end)
      assert winchester_station_with_direction_count == 1
      wedgemere_station_with_direction_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Wedgemere", direction_id: 0}, informed_entity)
        end)
      assert wedgemere_station_with_direction_count == 1
      west_medford_station_with_direction_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "West Medford", direction_id: 0}, informed_entity)
        end)
      assert west_medford_station_with_direction_count == 1
      north_station_with_direction_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "place-north", direction_id: 0}, informed_entity)
        end)
      assert north_station_with_direction_count == 1
      total_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 12
      anderson_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Anderson/ Woburn", direction_id: nil}, informed_entity)
        end)
      assert anderson_station_count == 1
      mishawum_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Mishawum", direction_id: nil}, informed_entity)
        end)
      assert mishawum_station_count == 1
      winchester_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Winchester Center", direction_id: nil}, informed_entity)
        end)
      assert winchester_station_count == 1
      wedgemere_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Wedgemere", direction_id: nil}, informed_entity)
        end)
      assert wedgemere_station_count == 1
      west_medford_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "West Medford", direction_id: nil}, informed_entity)
        end)
      assert west_medford_station_count == 1
      north_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "place-north", direction_id: nil}, informed_entity)
        end)
      assert north_station_count == 1
      anderson_station_with_direction_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Anderson/ Woburn", direction_id: 1}, informed_entity)
        end)
      assert anderson_station_with_direction_count == 1
      mishawum_station_with_direction_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Mishawum", direction_id: 1}, informed_entity)
        end)
      assert mishawum_station_with_direction_count == 1
      winchester_station_with_direction_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Winchester Center", direction_id: 1}, informed_entity)
        end)
      assert winchester_station_with_direction_count == 1
      wedgemere_station_with_direction_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "Wedgemere", direction_id: 1}, informed_entity)
        end)
      assert wedgemere_station_with_direction_count == 1
      west_medford_station_with_direction_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "West Medford", direction_id: 1}, informed_entity)
        end)
      assert west_medford_station_with_direction_count == 1
      north_station_with_direction_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "CR-Lowell", route_type: 2, stop: "place-north", direction_id: 1}, informed_entity)
        end)
      assert north_station_with_direction_count == 1
      total_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 12
    end

    test "constructs subscription with trips" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      trip_123_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{trip: "123"}, informed_entity)
        end)
      assert trip_123_count == 1
      trip_125_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{trip: "125"}, informed_entity)
        end)
      assert trip_125_count == 1
      trip_count =
        Enum.count(ie1, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 2

      trip_588_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{trip: "588"}, informed_entity)
        end)
      assert trip_588_count == 1
      trip_590_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{trip: "590"}, informed_entity)
        end)
      assert trip_590_count == 1
      trip_count =
        Enum.count(ie2, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 2
    end
  end

  describe "map_trip_options" do
    @test_date Calendar.Date.from_ordinal!(2017, 182)

    test "returns inbound results for origin destination" do
      use_cassette "north_to_anderson_woburn_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = CommuterRailMapper.map_trip_options("place-north", "Anderson/ Woburn", :weekday, @test_date)
        assert [%Trip{trip_number: "301", departure_time: ~T[05:35:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[05:59:00]},
                %Trip{trip_number: "303", departure_time: ~T[06:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[06:34:00]},
                %Trip{trip_number: "305", departure_time: ~T[06:37:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[07:01:00]},
                %Trip{trip_number: "307", departure_time: ~T[07:21:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[07:45:00]},
                %Trip{trip_number: "391", departure_time: ~T[07:42:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[08:02:00]},
                %Trip{trip_number: "309", departure_time: ~T[08:16:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[08:40:00]},
                %Trip{trip_number: "311", departure_time: ~T[09:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[09:39:00]},
                %Trip{trip_number: "313", departure_time: ~T[10:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[10:39:00]},
                %Trip{trip_number: "315", departure_time: ~T[11:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[11:39:00]},
                %Trip{trip_number: "317", departure_time: ~T[12:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[12:39:00]},
                %Trip{trip_number: "319", departure_time: ~T[13:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[13:39:00]} | rest] = trips


        assert [%Trip{trip_number: "321", departure_time: ~T[14:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[14:39:00]},
                %Trip{trip_number: "323", departure_time: ~T[15:00:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[15:24:00]},
                %Trip{trip_number: "325", departure_time: ~T[15:40:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[16:05:00]},
                %Trip{trip_number: "327", departure_time: ~T[16:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[16:40:00]},
                %Trip{trip_number: "329", departure_time: ~T[16:45:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[17:10:00]},
                %Trip{trip_number: "331", departure_time: ~T[17:10:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[17:35:00]},
                %Trip{trip_number: "333", departure_time: ~T[17:35:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[17:54:00]},
                %Trip{trip_number: "335", departure_time: ~T[17:50:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[18:15:00]},
                %Trip{trip_number: "337", departure_time: ~T[18:30:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[18:55:00]},
                %Trip{trip_number: "221", departure_time: ~T[18:55:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[19:20:00]},
                %Trip{trip_number: "339", departure_time: ~T[19:25:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[19:49:00]},
                %Trip{trip_number: "341", departure_time: ~T[20:35:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[20:59:00]},
                %Trip{trip_number: "343", departure_time: ~T[21:45:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[22:09:00]},
                %Trip{trip_number: "345", departure_time: ~T[22:55:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[23:19:00]},
                %Trip{trip_number: "347", departure_time: ~T[00:15:00], direction_id: 0, origin: {"North Station", "place-north"}, destination: {"Anderson/Woburn", "Anderson/ Woburn"}, arrival_time: ~T[00:39:00]}] = rest
      end
    end

    test "returns outbound results for origin destination" do
      use_cassette "anderson_woburn_to_north_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = CommuterRailMapper.map_trip_options("Anderson/ Woburn", "place-north", :weekday, @test_date)
        assert [%Trip{trip_number: "300", departure_time: ~T[05:56:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[06:22:00]},
                %Trip{trip_number: "302", departure_time: ~T[06:36:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[07:01:00]},
                %Trip{trip_number: "304", departure_time: ~T[07:01:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[07:27:00]},
                %Trip{trip_number: "306", departure_time: ~T[07:19:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[07:47:00]},
                %Trip{trip_number: "308", departure_time: ~T[07:41:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[08:06:00]},
                %Trip{trip_number: "310", departure_time: ~T[08:01:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[08:21:00]},
                %Trip{trip_number: "392", departure_time: ~T[08:21:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[08:47:00]},
                %Trip{trip_number: "312", departure_time: ~T[08:41:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[09:06:00]},
                %Trip{trip_number: "314", departure_time: ~T[09:06:00], direction_id: 1, origin: {"Anderson/Woburn", "Anderson/ Woburn"}, destination: {"North Station", "place-north"}, arrival_time: ~T[09:31:00]} | _t] = trips
      end
    end

    test "returns error for invalid origin destination combo" do
      assert :error = CommuterRailMapper.map_trip_options("place-north", "Providence", :weekday, @test_date)
    end

    test "returns saturday results" do
      use_cassette "waltham_to_porter_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = CommuterRailMapper.map_trip_options("Waltham", "place-portr", :saturday, @test_date)
        assert [%Trip{trip_number: "1400", departure_time: ~T[07:38:00], direction_id: 1, origin: {"Waltham", "Waltham"}, destination: {"Porter", "place-portr"}, arrival_time: ~T[07:50:00]},
                %Trip{trip_number: "1402", departure_time: ~T[09:53:00], direction_id: 1, origin: {"Waltham", "Waltham"}, destination: {"Porter", "place-portr"}, arrival_time: ~T[10:05:00]},
                %Trip{trip_number: "1404", departure_time: ~T[11:58:00], direction_id: 1, origin: {"Waltham", "Waltham"}, destination: {"Porter", "place-portr"}, arrival_time: ~T[12:10:00]},
                %Trip{trip_number: "1406", departure_time: ~T[14:23:00], direction_id: 1, origin: {"Waltham", "Waltham"}, destination: {"Porter", "place-portr"}, arrival_time: ~T[14:35:00]},
                %Trip{trip_number: "1408", departure_time: ~T[16:48:00], direction_id: 1, origin: {"Waltham", "Waltham"}, destination: {"Porter", "place-portr"}, arrival_time: ~T[17:00:00]},
                %Trip{trip_number: "1410", departure_time: ~T[19:18:00], direction_id: 1, origin: {"Waltham", "Waltham"}, destination: {"Porter", "place-portr"}, arrival_time: ~T[19:30:00]},
                %Trip{trip_number: "1412", departure_time: ~T[22:53:00], direction_id: 1, origin: {"Waltham", "Waltham"}, destination: {"Porter", "place-portr"}, arrival_time: ~T[23:05:00]} | _t] = trips
      end
    end

    test "returns sunday results" do
      use_cassette "porter_to_waltham_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = CommuterRailMapper.map_trip_options("place-portr", "Waltham", :sunday, @test_date)
        assert [%Trip{trip_number: "2401", departure_time: ~T[08:45:00], direction_id: 0, origin: {"Porter", "place-portr"}, destination: {"Waltham", "Waltham"}, arrival_time: ~T[08:57:00]},
                %Trip{trip_number: "2403", departure_time: ~T[10:55:00], direction_id: 0, origin: {"Porter", "place-portr"}, destination: {"Waltham", "Waltham"}, arrival_time: ~T[11:07:00]},
                %Trip{trip_number: "2405", departure_time: ~T[13:20:00], direction_id: 0, origin: {"Porter", "place-portr"}, destination: {"Waltham", "Waltham"}, arrival_time: ~T[13:32:00]},
                %Trip{trip_number: "2407", departure_time: ~T[15:40:00], direction_id: 0, origin: {"Porter", "place-portr"}, destination: {"Waltham", "Waltham"}, arrival_time: ~T[15:52:00]},
                %Trip{trip_number: "2409", departure_time: ~T[17:55:00], direction_id: 0, origin: {"Porter", "place-portr"}, destination: {"Waltham", "Waltham"}, arrival_time: ~T[18:07:00]},
                %Trip{trip_number: "2411", departure_time: ~T[20:05:00], direction_id: 0, origin: {"Porter", "place-portr"}, destination: {"Waltham", "Waltham"}, arrival_time: ~T[20:17:00]},
                %Trip{trip_number: "2413", departure_time: ~T[23:40:00], direction_id: 0, origin: {"Porter", "place-portr"}, destination: {"Waltham", "Waltham"}, arrival_time: ~T[23:52:00]}] = trips
      end
    end
  end

  describe "get_trip_info" do
    test "returns trip options with closest trip preselected" do
      {:ok, trips} = CommuterRailMapper.get_trip_info("Reading", "place-north", :weekday, "10:00:00")
      assert [%AlertProcessor.Model.Trip{trip_number: "200", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "202", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "204", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "286", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "288", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "290", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "210", selected: true},
              %AlertProcessor.Model.Trip{trip_number: "212", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "214", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "216", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "292", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "294", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "296", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "298", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "226", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "228", selected: false}] = trips
    end

    test "returns trip options with preselected values" do
      {:ok, trips} = CommuterRailMapper.get_trip_info("Reading", "place-north", :weekday, ["286", "298"])
      assert [%AlertProcessor.Model.Trip{trip_number: "200", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "202", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "204", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "286", selected: true},
              %AlertProcessor.Model.Trip{trip_number: "288", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "290", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "210", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "212", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "214", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "216", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "292", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "294", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "296", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "298", selected: true},
              %AlertProcessor.Model.Trip{trip_number: "226", selected: false},
              %AlertProcessor.Model.Trip{trip_number: "228", selected: false}] = trips
    end

    test "returns error if origin/destination are not on the same route" do
      :error = CommuterRailMapper.get_trip_info("Anderson/ Woburn", "place-rugg", :sunday, "10:00:00")
      :error = CommuterRailMapper.get_trip_info("Anderson/ Woburn", "place-rugg", :sunday, ["2302", "2308"])
    end
  end

  describe "populate_trip_options one_way" do
    test "one_way with timestamp returns trip options with closest trip preselected" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-north",
        "relevant_days" => "weekday",
        "departure_start" => "10:00:00",
        "trip_type" => "one_way"
      }
      {:ok, %{departure_trips: departure_trips}} = CommuterRailMapper.populate_trip_options(params)
      selected_trips = Enum.filter(departure_trips, & &1.selected)
      assert [%Trip{trip_number: "316", departure_time: ~T[09:36:00], selected: true}] = selected_trips
    end

    test "one_way with trip_ids returns trip options with preselected trips" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-north",
        "relevant_days" => "weekday",
        "trips" => ["316", "318"],
        "trip_type" => "one_way"
      }
      {:ok, %{departure_trips: departure_trips}} = CommuterRailMapper.populate_trip_options(params)
      selected_trips = Enum.filter(departure_trips, & &1.selected)
      assert [
        %Trip{trip_number: "316", selected: true},
        %Trip{trip_number: "318", selected: true}
      ] = selected_trips
    end

    test "one_way with_timestamp returns error and message with invalid origin/destination combo" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-rugg",
        "relevant_days" => "weekday",
        "departure_start" => "10:00:00",
        "trip_type" => "one_way"
      }
      {:error, _} = CommuterRailMapper.populate_trip_options(params)
    end

    test "one_way with trip_ids returns error and message with invalid origin/destination combo" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-rugg",
        "relevant_days" => "weekday",
        "trips" => ["316", "318"],
        "trip_type" => "one_way"
      }
      {:error, _} = CommuterRailMapper.populate_trip_options(params)
    end
  end

  describe "populate_trip_options round_trip" do
    test "round_trip with timestamp returns trip options with closest trip preselected" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-north",
        "relevant_days" => "weekday",
        "departure_start" => "10:00:00",
        "return_start" => "16:00:00",
        "trip_type" => "round_trip"
      }
      {:ok, %{
          departure_trips: departure_trips,
          return_trips: return_trips
        }
      } = CommuterRailMapper.populate_trip_options(params)
      selected_trips = Enum.filter(departure_trips, & &1.selected)
      selected_return_trips = Enum.filter(return_trips, & &1.selected)
      assert [
        %Trip{trip_number: "316", departure_time: ~T[09:36:00], selected: true},
      ] = selected_trips
      assert [
        %Trip{trip_number: "327", departure_time: ~T[16:15:00], selected: true}
      ] = selected_return_trips
    end

    test "round_trip with trip_ids returns trip options with preselected trips" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-north",
        "relevant_days" => "weekday",
        "trips" => ["316", "318"],
        "return_trips" => ["331", "221"],
        "trip_type" => "round_trip"
      }
      {:ok, %{
          departure_trips: departure_trips,
          return_trips: return_trips
        }
      } = CommuterRailMapper.populate_trip_options(params)
      selected_trips = Enum.filter(departure_trips, & &1.selected)
      selected_return_trips = Enum.filter(return_trips, & &1.selected)
      assert [
        %Trip{trip_number: "316", selected: true},
        %Trip{trip_number: "318", selected: true}
      ] = selected_trips
      assert [
        %Trip{trip_number: "331", selected: true},
        %Trip{trip_number: "221", selected: true}
      ] = selected_return_trips
    end

    test "round_trip with_timestamp returns error and message with invalid origin/destination combo" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-rugg",
        "relevant_days" => "weekday",
        "departure_start" => "10:00:00",
        "return_start" => "16:00:00",
        "trip_type" => "round_trip"
      }
      {:error, _} = CommuterRailMapper.populate_trip_options(params)
    end

    test "round_trip with trip_ids returns error and message with invalid origin/destination combo" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-rugg",
        "relevant_days" => "weekday",
        "trips" => ["316", "318"],
        "return_trips" => ["331", "221"],
        "trip_type" => "round_trip"
      }
      {:error, _} = CommuterRailMapper.populate_trip_options(params)
    end
  end

  describe "trip_schedule_info_map" do
    @test_date Calendar.Date.from_ordinal!(2017, 201)

    test "maps schedule info between two stations on weekday" do
      use_cassette "trip_schedule_info_weekday_commuter_rail", custom: true, clear_mock: true, match_requests_on: [:query] do
        trip_schedule_info_map = CommuterRailMapper.trip_schedule_info_map("Newburyport", "Rowley", :weekday, @test_date)
        assert %{
          {"Newburyport", "NB161"} => _,
          {"Rowley", "NB161"} => _,
          {"Newburyport", "NB164"} => _,
          {"Rowley", "NB164"} => _,
          {"Newburyport", "NB173"} => _,
          {"Rowley", "NB173"} => _,
        } = trip_schedule_info_map
      end
    end

    test "maps schedule info between two stations on saturday" do
      use_cassette "trip_schedule_info_saturday_commuter_rail", custom: true, clear_mock: true, match_requests_on: [:query] do
        trip_schedule_info_map = CommuterRailMapper.trip_schedule_info_map("place-north", "Fitchburg", :saturday, @test_date)
        assert %{
          {"place-north", "1401"} => _,
          {"Fitchburg", "1401"} => _,
          {"place-north", "1404"} => _,
          {"Fitchburg", "1404"} => _,
          {"place-north", "1410"} => _,
          {"Fitchburg", "1410"} => _,
        } = trip_schedule_info_map
      end
    end

    test "maps schedule info between two stations on sunday" do
      use_cassette "trip_schedule_info_sunday_commuter_rail", custom: true, clear_mock: true, match_requests_on: [:query] do
        trip_schedule_info_map = CommuterRailMapper.trip_schedule_info_map("Lowell", "place-north", :saturday, @test_date)
        assert %{
          {"place-north", "1300"} => _,
          {"Lowell", "1300"} => _,
          {"place-north", "1305"} => _,
          {"Lowell", "1305"} => _,
          {"place-north", "1315"} => _,
          {"Lowell", "1315"} => _,
        } = trip_schedule_info_map
      end
    end
  end

  describe "build_subscription_transaction" do
    @round_trip_params %{
      "origin" => "place-north",
      "destination" => "Anderson/ Woburn",
      "trips" => ["123", "125"],
      "return_trips" => ["588", "590"],
      "relevant_days" => ["weekday"],
      "departure_start" => ~T[12:00:00],
      "departure_end" => ~T[14:00:00],
      "return_start" => ~T[18:00:00],
      "return_end" => ~T[20:00:00],
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "it builds a multi struct to persist subscriptions and informed_entities" do
      user = insert(:user)
      {:ok, subscription_infos} = CommuterRailMapper.map_subscriptions(@round_trip_params)
      multi = CommuterRailMapper.build_subscription_transaction(subscription_infos, user, user.id)
      result = Ecto.Multi.to_list(multi)

      assert {{:subscription, 0}, {:run, function1}} = List.first(result)
      assert {{:new_informed_entity, 0, 0}, {:run, _}} = Enum.at(result, 1)
      assert {{:subscription, 1}, {:run, function2}} = Enum.at(result, 19)
      assert {{:new_informed_entity, 1, 0}, {:run, _}} = Enum.at(result, 20)
      {:ok, %{model: subscription1}} = function1.(nil)
      {:ok, %{model: subscription2}} = function2.(nil)
      assert subscription1.id != nil
      assert subscription2.id != nil
    end
  end

  describe "build_update_subscription_transaction" do
    test "it builds a multi struct to update subscription" do
      user = insert(:user)
      subscription =
          subscription_factory()
          |> Map.put(:informed_entities, commuter_rail_subscription_entities())
          |> commuter_rail_subscription()
          |> Map.merge(%{user: user, relevant_days: [:weekday]})
          |> insert()

      params = %{
        "alert_priority_type" => :high,
        "end_time" => ~T[20:59:00],
        "start_time" => ~T[20:35:00],
        "trips" => ["341"]
      }

      multi = CommuterRailMapper.build_update_subscription_transaction(subscription, params, user.id)

      assert [
        {{:new_informed_entity, 0}, {:run, function1}},
        {{:remove_old, 0}, {:run, function2}},
        {{:remove_old, 1}, {:run, function3}},
        {{:subscription}, {:run, function4}}
      ] = Ecto.Multi.to_list(multi)
      assert {:ok, %{model: informed_entity1, version: %{event: "insert"}}} = function1.(nil)
      assert informed_entity1.subscription_id == subscription.id
      assert informed_entity1.activities == InformedEntity.default_entity_activities()
      assert {:ok, %{model: _informed_entity2, version: %{event: "delete"}}} = function2.(nil)
      assert {:ok, %{model: _informed_entity3, version: %{event: "delete"}}} = function3.(nil)
      assert {:ok, %{model: updated_subscription, version: %{event: "update"}}} = function4.(nil)
      assert updated_subscription.id == subscription.id
    end
  end
end
