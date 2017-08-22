defmodule AlertProcessor.Subscription.SubwayMapperTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Subscription.SubwayMapper
  alias AlertProcessor.Model.InformedEntity

  @one_way_params %{
    "origin" => "place-davis",
    "destination" => "place-harsq",
    "relevant_days" => ["weekday", "saturday"],
    "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
    "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
    "return_start" => nil,
    "return_end" => nil,
    "alert_priority_type" => "low",
    "amenities" => ["elevator"]
  }

  @round_trip_params %{
    "origin" => "place-davis",
    "destination" => "place-harsq",
    "relevant_days" => ["weekday", "saturday"],
    "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
    "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
    "return_start" => DateTime.from_naive!(~N[2017-07-20 18:00:00], "Etc/UTC"),
    "return_end" => DateTime.from_naive!(~N[2017-07-20 20:00:00], "Etc/UTC"),
    "alert_priority_type" => "low",
    "amenities" => ["elevator"]
  }

  @green_line_one_way_params %{
    "origin" => "place-north",
    "destination" => "place-kencl",
    "relevant_days" => ["weekday", "sunday"],
    "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
    "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
    "return_start" => nil,
    "return_end" => nil,
    "alert_priority_type" => "low",
    "amenities" => []
  }

  @roaming_params Map.put(@one_way_params, "roaming", "true")

  describe "one way" do
    test "constructs subscription with severity" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@one_way_params)
      assert subscription.type == :subway
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@one_way_params)
      assert subscription.origin == "Davis"
      assert subscription.destination == "Harvard"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@one_way_params)
      assert subscription.start_time == ~T[12:00:00]
      assert subscription.end_time == ~T[14:00:00]
      assert subscription.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@one_way_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-davis"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@one_way_params)
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
    end

    test "constructs subscription with route in other direction" do
      reverse_trip_params = Map.merge(@one_way_params, %{"destination" => "place-davis", "origin" => "place-harsq"})
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(reverse_trip_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 1}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@one_way_params)
      davis_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-davis"}, informed_entity)
        end)
      assert davis_station_count == 1
      porter_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-portr"}, informed_entity)
        end)
      assert porter_station_count == 1
      harvard_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-harsq"}, informed_entity)
        end)
      assert harvard_station_count == 1
      total_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 3
    end
  end

  describe "round trip" do
    test "constructs subscription with severity" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = SubwayMapper.map_subscriptions(@round_trip_params)
      assert sub1.alert_priority_type == :low
      assert sub2.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = SubwayMapper.map_subscriptions(@round_trip_params)
      assert sub1.type == :subway
      assert sub2.type == :subway
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = SubwayMapper.map_subscriptions(@round_trip_params)
      assert sub1.origin == "Davis"
      assert sub1.destination == "Harvard"
      assert sub2.origin == "Harvard"
      assert sub2.destination == "Davis"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = SubwayMapper.map_subscriptions(@round_trip_params)
      assert sub1.start_time == ~T[12:00:00]
      assert sub1.end_time == ~T[14:00:00]
      assert sub1.relevant_days == [:weekday, :saturday]
      assert sub2.start_time == ~T[18:00:00]
      assert sub2.end_time == ~T[20:00:00]
      assert sub2.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = SubwayMapper.map_subscriptions(@round_trip_params)
      amenity_informed_entities_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-davis"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
      amenity_informed_entities_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-davis"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = SubwayMapper.map_subscriptions(@round_trip_params)
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = SubwayMapper.map_subscriptions(@round_trip_params)
      route_type_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 1}, informed_entity)
        end)
      assert route_type_entity_count == 1
      route_type_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 1}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = SubwayMapper.map_subscriptions(@round_trip_params)
      davis_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-davis"}, informed_entity)
        end)
      assert davis_station_count == 1
      porter_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-portr"}, informed_entity)
        end)
      assert porter_station_count == 1
      harvard_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-harsq"}, informed_entity)
        end)
      assert harvard_station_count == 1
      total_station_count =
        Enum.count(ie1, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 3
      davis_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-davis"}, informed_entity)
        end)
      assert davis_station_count == 1
      porter_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-portr"}, informed_entity)
        end)
      assert porter_station_count == 1
      harvard_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Red", route_type: 1, stop: "place-harsq"}, informed_entity)
        end)
      assert harvard_station_count == 1
      total_station_count =
        Enum.count(ie2, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 3
    end
  end

  describe "green line" do
    test "constructs subscription with severity" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@green_line_one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@green_line_one_way_params)
      assert subscription.type == :subway
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@green_line_one_way_params)
      assert subscription.origin == "North Station"
      assert subscription.destination == "Kenmore"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@green_line_one_way_params)
      assert subscription.start_time == ~T[12:00:00]
      assert subscription.end_time == ~T[14:00:00]
      assert subscription.relevant_days == [:weekday, :sunday]
    end

    test "constructs subscription without amenities" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@green_line_one_way_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator}, informed_entity)
        end)
      assert amenity_informed_entities_count == 0
    end

    test "constructs subscription with route" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@green_line_one_way_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-" <> _, route_type: 0, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 3
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-" <> _, route_type: 0, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 3
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@green_line_one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 0}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@green_line_one_way_params)
      north_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-" <> _, route_type: 0, stop: "place-north"}, informed_entity)
        end)
      assert north_station_count == 3
      kenmore_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-" <> _, route_type: 0, stop: "place-kencl"}, informed_entity)
        end)
      assert kenmore_station_count == 3
      arlington_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Green-" <> _, route_type: 0, stop: "place-armnl"}, informed_entity)
        end)
      assert arlington_station_count == 3
      total_station_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :stop
        end)
      assert total_station_count == 27
    end
  end

  describe "roaming" do
    test "constructs subscription with severity" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@roaming_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@roaming_params)
      assert subscription.type == :subway
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@roaming_params)
      assert subscription.origin == "Davis"
      assert subscription.destination == "Harvard"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{subscription, _ie}]} = SubwayMapper.map_subscriptions(@roaming_params)
      assert subscription.start_time == ~T[12:00:00]
      assert subscription.end_time == ~T[14:00:00]
      assert subscription.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@roaming_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-davis"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route and direction" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@roaming_params)
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
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@roaming_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 1}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub, informed_entities}]} = SubwayMapper.map_subscriptions(@roaming_params)
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

  describe "build_subscription_transaction" do
    @round_trip_params %{
      "origin" => "place-davis",
      "destination" => "place-harsq",
      "relevant_days" => ["weekday", "saturday"],
      "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
      "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
      "return_start" => DateTime.from_naive!(~N[2017-07-20 18:00:00], "Etc/UTC"),
      "return_end" => DateTime.from_naive!(~N[2017-07-20 20:00:00], "Etc/UTC"),
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "it builds a multi struct to persist subscriptions and informed_entities" do
      user = insert(:user)
      {:ok, subscription_infos} = SubwayMapper.map_subscriptions(@round_trip_params)
      multi = SubwayMapper.build_subscription_transaction(subscription_infos, user)
      result = Ecto.Multi.to_list(multi)

      assert {{:subscription, 0}, {:run, function1}} = List.first(result)
      assert {{:informed_entity, 0, 0}, {:run, _}} = Enum.at(result, 1)
      assert {{:subscription, 1}, {:run, function2}} = Enum.at(result, 8)
      assert {{:informed_entity, 1, 0}, {:run, _}} = Enum.at(result, 9)
      {:ok, %{model: subscription1}} = function1.(nil)
      {:ok, %{model: subscription2}} = function2.(nil)
      assert subscription1.id != nil
      assert subscription2.id != nil
    end
  end
end
