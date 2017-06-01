defmodule AlertProcessor.Subscription.SubwayMapperTest do
  use ExUnit.Case
  alias AlertProcessor.Subscription.SubwayMapper
  alias AlertProcessor.Model.InformedEntity

  @one_way_params %{
    "origin" => "place-davis",
    "destination" => "place-harsq",
    "relevant_days" => ["weekday", "saturday"],
    "departure_start" => "12:00:00",
    "departure_end" => "14:00:00",
    "return_start" => nil,
    "return_end" => nil,
    "alert_priority_type" => "low",
    "amenities" => ["elevator"]
  }

  @round_trip_params %{
    "origin" => "place-davis",
    "destination" => "place-harsq",
    "relevant_days" => ["weekday", "saturday"],
    "departure_start" => "12:00:00",
    "departure_end" => "14:00:00",
    "return_start" => "18:00:00",
    "return_end" => "20:00:00",
    "alert_priority_type" => "low",
    "amenities" => ["elevator"]
  }

  @green_line_one_way_params %{
    "origin" => "place-north",
    "destination" => "place-kencl",
    "relevant_days" => ["weekday", "sunday"],
    "departure_start" => "12:00:00",
    "departure_end" => "14:00:00",
    "return_start" => nil,
    "return_end" => nil,
    "alert_priority_type" => "low",
    "amenities" => []
  }

  @roaming_params Map.put(@one_way_params, "roaming", "true")

  describe "one way" do
    test "constructs subscription with severity" do
      {:ok, [subscription], _informed_entities} = SubwayMapper.map_subscription(@one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with timeframe" do
      {:ok, [subscription], _informed_entities} = SubwayMapper.map_subscription(@one_way_params)
      assert subscription.start_time == ~T[16:00:00]
      assert subscription.end_time == ~T[18:00:00]
      assert subscription.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with amenities" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@one_way_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-davis"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@one_way_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 1}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@one_way_params)
      davis_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-davis"}, informed_entity)
        end)
      assert davis_station_count == 1
      harvard_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-harsq"}, informed_entity)
        end)
      assert harvard_station_count == 1
      total_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 2
    end
  end

  describe "round trip" do
    test "constructs subscription with severity" do
      {:ok, [sub1, sub2], _informed_entities} = SubwayMapper.map_subscription(@round_trip_params)
      assert sub1.alert_priority_type == :low
      assert sub2.alert_priority_type == :low
    end

    test "constructs subscription with timeframe" do
      {:ok, [sub1, sub2], [_ie | _t]} = SubwayMapper.map_subscription(@round_trip_params)
      assert sub1.start_time == ~T[16:00:00]
      assert sub1.end_time == ~T[18:00:00]
      assert sub1.relevant_days == [:weekday, :saturday]
      assert sub2.start_time == ~T[22:00:00]
      assert sub2.end_time == ~T[00:00:00]
      assert sub2.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with amenities" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@round_trip_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-davis"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@round_trip_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@round_trip_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 1}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@round_trip_params)
      davis_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-davis"}, informed_entity)
        end)
      assert davis_station_count == 1
      harvard_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-harsq"}, informed_entity)
        end)
      assert harvard_station_count == 1
      total_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 2
    end
  end

  describe "green line" do
    test "constructs subscription with severity" do
      {:ok, [subscription], _informed_entities} = SubwayMapper.map_subscription(@green_line_one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with timeframe" do
      {:ok, [subscription], _informed_entities} = SubwayMapper.map_subscription(@green_line_one_way_params)
      assert subscription.start_time == ~T[16:00:00]
      assert subscription.end_time == ~T[18:00:00]
      assert subscription.relevant_days == [:weekday, :sunday]
    end

    test "constructs subscription without amenities" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@green_line_one_way_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator}, informed_entity)
        end)
      assert amenity_informed_entities_count == 0
    end

    test "constructs subscription with route" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@green_line_one_way_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-C", route_type: 0, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-C", route_type: 0, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-C", route_type: 0, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@green_line_one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 0}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@green_line_one_way_params)
      davis_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-C", route_type: 0, stop: "place-north"}, informed_entity)
        end)
      assert davis_station_count == 1
      harvard_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-C", route_type: 0, stop: "place-kencl"}, informed_entity)
        end)
      assert harvard_station_count == 1
      total_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 2
    end
  end

  describe "roaming" do
    test "constructs subscription with severity" do
      {:ok, [subscription], _informed_entities} = SubwayMapper.map_subscription(@roaming_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with timeframe" do
      {:ok, [subscription], _informed_entities} = SubwayMapper.map_subscription(@roaming_params)
      assert subscription.start_time == ~T[16:00:00]
      assert subscription.end_time == ~T[18:00:00]
      assert subscription.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with amenities" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@roaming_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-davis"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@roaming_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@roaming_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 1}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, _subscriptions, informed_entities} = SubwayMapper.map_subscription(@roaming_params)
      davis_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-davis"}, informed_entity)
        end)
      assert davis_station_count == 1
      davis_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-portr"}, informed_entity)
        end)
      assert davis_station_count == 1
      harvard_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-harsq"}, informed_entity)
        end)
      assert harvard_station_count == 1
      alewife_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-alfcl"}, informed_entity)
        end)
      assert alewife_station_count == 0
      central_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-censq"}, informed_entity)
        end)
      assert central_station_count == 0
      total_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 3
    end
  end
end
