defmodule AlertProcessor.Subscription.BusMapperTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Subscription.BusMapper
  alias AlertProcessor.Model.InformedEntity

  @one_way_params %{
    "routes" => ["16 - 1"],
    "relevant_days" => ["weekday", "saturday"],
    "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
    "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
    "return_start" => nil,
    "return_end" => nil,
    "alert_priority_type" => "low",
    "trip_type" => "one_way"
  }

  @round_trip_params %{
    "routes" => ["16 - 0"],
    "relevant_days" => ["weekday", "saturday"],
    "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
    "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
    "return_start" => DateTime.from_naive!(~N[2017-07-20 18:00:00], "Etc/UTC"),
    "return_end" => DateTime.from_naive!(~N[2017-07-20 20:00:00], "Etc/UTC"),
    "alert_priority_type" => "low",
    "trip_type" => "round_trip"
  }

  describe "one way" do
    test "constructs subscription with severity" do
      {:ok, [{subscription, _ie}]} = BusMapper.map_subscription(@one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = BusMapper.map_subscription(@one_way_params)
      assert subscription.type == :bus
    end

    test "constructs subscription with timeframe" do
      {:ok, [{subscription, _ie}]} = BusMapper.map_subscription(@one_way_params)
      assert subscription.start_time == ~T[12:00:00]
      assert subscription.end_time == ~T[14:00:00]
      assert subscription.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with route" do
      {:ok, [{_subscription, informed_entities}]} = BusMapper.map_subscription(@one_way_params)
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
      {:ok, [{_subscription, informed_entities}]} = BusMapper.map_subscription(@one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 3}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end
  end

  describe "round trip" do
    test "constructs subscription with severity" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = BusMapper.map_subscription(@round_trip_params)
      assert sub1.alert_priority_type == :low
      assert sub2.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = BusMapper.map_subscription(@round_trip_params)
      assert sub1.type == :bus
      assert sub2.type == :bus
    end

    test "constructs subscription with timeframe" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = BusMapper.map_subscription(@round_trip_params)
      assert sub1.start_time == ~T[12:00:00]
      assert sub1.end_time == ~T[14:00:00]
      assert sub1.relevant_days == [:weekday, :saturday]
      assert sub2.start_time == ~T[18:00:00]
      assert sub2.end_time == ~T[20:00:00]
      assert sub2.relevant_days == [:weekday, :saturday]
    end

    test "constructs subscription with route" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = BusMapper.map_subscription(@round_trip_params)
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1


      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route in other direction" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = BusMapper.map_subscription(Map.merge(@round_trip_params, %{"routes" => ["16 - 1"]}))
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1


      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "16", route_type: 3, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = BusMapper.map_subscription(@round_trip_params)
      route_type_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 3}, informed_entity)
        end)
      assert route_type_entity_count == 1

      route_type_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 3}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end
  end

  describe "build_subscription_transaction" do
    @round_trip_params %{
      "routes" => ["16 - 0"],
      "relevant_days" => ["weekday", "saturday"],
      "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
      "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
      "return_start" => DateTime.from_naive!(~N[2017-07-20 18:00:00], "Etc/UTC"),
      "return_end" => DateTime.from_naive!(~N[2017-07-20 20:00:00], "Etc/UTC"),
      "alert_priority_type" => "low",
      "trip_type" => "round_trip"
    }

    test "it builds a multi struct to persist subscriptions and informed_entities" do
      user = insert(:user)
      {:ok, subscription_infos} = BusMapper.map_subscription(@round_trip_params)
      multi = BusMapper.build_subscription_transaction(subscription_infos, user, user.id)
      result = Ecto.Multi.to_list(multi)

      assert {{:subscription, 0}, {:run, function1}} = List.first(result)
      assert {{:new_informed_entity, 0, 0}, {:run, _}} = Enum.at(result, 1)
      assert {{:subscription, 1}, {:run, function2}} = Enum.at(result, 4)
      assert {{:new_informed_entity, 1, 0}, {:run, _}} = Enum.at(result, 5)
      {:ok, %{model: subscription1}} = function1.(nil)
      {:ok, %{model: subscription2}} = function2.(nil)
      assert subscription1.id != nil
      assert subscription2.id != nil
    end
  end
end
