defmodule AlertProcessor.Subscription.BusMapperTest do
  use ExUnit.Case
  alias AlertProcessor.Subscription.BusMapper
  alias AlertProcessor.Model.InformedEntity

  @one_way_params %{
    "route" => "16 - 1",
    "relevant_days" => ["weekday", "saturday"],
    "departure_start" => "12:00:00",
    "departure_end" => "14:00:00",
    "return_start" => nil,
    "return_end" => nil,
    "alert_priority_type" => "low",
    "trip_type" => "one_way"
  }

  @round_trip_params %{
    "route" => "16 - 0",
    "relevant_days" => ["weekday", "saturday"],
    "departure_start" => "12:00:00",
    "departure_end" => "14:00:00",
    "return_start" => "18:00:00",
    "return_end" => "20:00:00",
    "alert_priority_type" => "low",
    "trip_type" => "round_trip"
  }

  describe "one way" do
    test "constructs subscription with severity" do
      {:ok, [subscription], _informed_entities} = BusMapper.map_subscription(@one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [subscription], _informed_entities} = BusMapper.map_subscription(@one_way_params)
      assert subscription.type == :bus
    end

    test "constructs subscription with timeframe" do
      {:ok, [subscription], _informed_entities} = BusMapper.map_subscription(@one_way_params)
      assert subscription.start_time == ~T[16:00:00]
      assert subscription.end_time == ~T[18:00:00]
      assert subscription.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with timeframe, no return values" do
      params = Map.drop(@one_way_params, ["return_start", "return_end"])

      {:ok, [subscription], _informed_entities} = BusMapper.map_subscription(params)
      assert subscription.start_time == ~T[16:00:00]
      assert subscription.end_time == ~T[18:00:00]
      assert subscription.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with route" do
      {:ok, _subscriptions, informed_entities} = BusMapper.map_subscription(@one_way_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 0
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, _subscriptions, informed_entities} = BusMapper.map_subscription(@one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 3}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end
  end

  describe "round trip" do
    test "constructs subscription with severity" do
      {:ok, [sub1, sub2], _informed_entities} = BusMapper.map_subscription(@round_trip_params)
      assert sub1.alert_priority_type == :low
      assert sub2.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [sub1, sub2], _informed_entities} = BusMapper.map_subscription(@round_trip_params)
      assert sub1.type == :bus
      assert sub2.type == :bus
    end

    test "constructs subscription with timeframe" do
      {:ok, [sub1, sub2], _informed_entities} = BusMapper.map_subscription(@round_trip_params)
      assert sub1.start_time == ~T[16:00:00]
      assert sub1.end_time == ~T[18:00:00]
      assert sub1.relevant_days == [:weekday, :saturday]
      assert sub2.start_time == ~T[22:00:00]
      assert sub2.end_time == ~T[00:00:00]
      assert sub2.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with route" do
      {:ok, _subscriptions, informed_entities} = BusMapper.map_subscription(@round_trip_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 0
    end

    test "constructs subscription with route type" do
      {:ok, _subscriptions, informed_entities} = BusMapper.map_subscription(@round_trip_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 3}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end
  end
end
