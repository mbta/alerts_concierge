defmodule AlertProcessor.Subscription.AmenitiesMapperTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Subscription.AmenitiesMapper
  alias AlertProcessor.Model.InformedEntity

  @params %{
    "amenities" => ["elevator"],
    "stops" => "North Station,South Station",
    "routes" => ["red"],
    "relevant_days" => ["weekday"]
  }

  describe "elevator only" do
    test "constructs subscription with high severity" do
      {:ok, [{subscription, _ie}]} = AmenitiesMapper.map_subscriptions(@params)
      assert subscription.alert_priority_type == :high
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = AmenitiesMapper.map_subscriptions(@params)
      assert subscription.type == :amenity
    end

    test "constructs subscription with 00:00:00 to 23:59:59 timeframe" do
      {:ok, [{subscription, _ie}]} = AmenitiesMapper.map_subscriptions(@params)
      assert subscription.start_time == ~T[00:00:00]
      assert subscription.end_time == ~T[23:59:59]
    end

    test "constructs subscription with routes" do
      {:ok, [{_subscription, informed_entities}]} = AmenitiesMapper.map_subscriptions(@params)
      red_line_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, route: "Red"}, informed_entity)
        end)
      assert red_line_entities_count == 1

      blue_line_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, route: "Blue"}, informed_entity)
        end)
      assert blue_line_entities_count == 0
    end

    test "constructs subscription with stops" do
      {:ok, [{_subscription, informed_entities}]} = AmenitiesMapper.map_subscriptions(@params)
      north_station_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-north"}, informed_entity)
        end)
      assert north_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-sstat"}, informed_entity)
        end)
      assert south_station_entities_count == 1
    end
  end

  describe "elevator and escalator" do
    test "constructs subscription with high severity" do
      {:ok, [{subscription, _ie}]} = AmenitiesMapper.map_subscriptions(Map.merge(@params, %{"amenities" => ["elevator", "escalator"]}))
      assert subscription.alert_priority_type == :high
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = AmenitiesMapper.map_subscriptions(Map.merge(@params, %{"amenities" => ["elevator", "escalator"]}))
      assert subscription.type == :amenity
    end

    test "constructs subscription with 00:00:00 to 23:59:59 timeframe" do
      {:ok, [{subscription, _ie}]} = AmenitiesMapper.map_subscriptions(Map.merge(@params, %{"amenities" => ["elevator", "escalator"]}))
      assert subscription.start_time == ~T[00:00:00]
      assert subscription.end_time == ~T[23:59:59]
    end

    test "constructs subscription with routes" do
      {:ok, [{_subscription, informed_entities}]} = AmenitiesMapper.map_subscriptions(Map.merge(@params, %{"amenities" => ["elevator", "escalator"]}))
      red_line_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, route: "Red"}, informed_entity)
        end)
      assert red_line_entities_count == 1

      blue_line_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, route: "Blue"}, informed_entity)
        end)
      assert blue_line_entities_count == 0
    end

    test "constructs subscription with stops" do
      {:ok, [{_subscription, informed_entities}]} = AmenitiesMapper.map_subscriptions(Map.merge(@params, %{"amenities" => ["elevator", "escalator"]}))
      north_station_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-north"}, informed_entity)
        end)
      assert north_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-sstat"}, informed_entity)
        end)
      assert south_station_entities_count == 1
    end
  end

  describe "build_subscription_transaction" do
    @params %{
      "amenities" => ["elevator"],
      "stops" => "North Station,South Station",
      "routes" => ["red"],
      "relevant_days" => ["weekday"]
    }

    test "it builds a multi struct to persist subscriptions" do
      user = insert(:user)
      {:ok, subscription_infos} = AmenitiesMapper.map_subscriptions(@params)
      multi = AmenitiesMapper.build_subscription_transaction(subscription_infos, user)
      assert [
          {{:subscription, 0}, {:insert, subscription_changeset, []}}
        ] = Ecto.Multi.to_list(multi)
      assert subscription_changeset.valid?
    end
  end
end
