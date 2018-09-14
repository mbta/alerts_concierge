defmodule AlertProcessor.Subscription.AccessibilityMapperTest do
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Subscription.AccessibilityMapper
  alias AlertProcessor.Model.InformedEntity

  @params %{
    "accessibility" => ["elevator"],
    "stops" => ["place-north", "place-sstat"],
    "routes" => ["red"],
    "relevant_days" => ["weekday"]
  }

  describe "elevator only" do
    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = AccessibilityMapper.map_subscriptions(@params)
      assert subscription.type == :accessibility
    end

    test "constructs subscription with 00:00:00 to 23:59:59 timeframe" do
      {:ok, [{subscription, _ie}]} = AccessibilityMapper.map_subscriptions(@params)
      assert subscription.start_time == ~T[00:00:00]
      assert subscription.end_time == ~T[23:59:59]
    end

    test "constructs subscription with routes" do
      {:ok, [{_subscription, informed_entities}]} = AccessibilityMapper.map_subscriptions(@params)

      red_line_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :elevator,
              route: "Red",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert red_line_entities_count == 1

      blue_line_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :elevator,
              route: "Blue",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert blue_line_entities_count == 0
    end

    test "constructs subscription with stops" do
      {:ok, [{_subscription, informed_entities}]} = AccessibilityMapper.map_subscriptions(@params)

      north_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :elevator,
              stop: "place-north",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert north_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :elevator,
              stop: "place-sstat",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert south_station_entities_count == 1
    end

    test "includes portable_boarding_lift type with elevator accessibility type subscriptions" do
      {:ok, [{_subscription, informed_entities}]} = AccessibilityMapper.map_subscriptions(@params)

      north_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :elevator,
              stop: "place-north",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert north_station_entities_count == 1

      north_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :portable_boarding_lift,
              stop: "place-north",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert north_station_entities_count == 1

      north_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :elevated_subplatform,
              stop: "place-north",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert north_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :elevator,
              stop: "place-sstat",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert south_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :portable_boarding_lift,
              stop: "place-sstat",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert south_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :elevated_subplatform,
              stop: "place-sstat",
              activities: ["USING_WHEELCHAIR"]
            },
            informed_entity
          )
        end)

      assert south_station_entities_count == 1
    end
  end

  describe "escalator" do
    test "creates expected entities" do
      {:ok, [{_subscription, informed_entities}]} =
        AccessibilityMapper.map_subscriptions(Map.put(@params, "accessibility", ["escalator"]))

      north_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :escalator,
              stop: "place-north",
              activities: ["USING_ESCALATOR"]
            },
            informed_entity
          )
        end)

      assert north_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :escalator,
              stop: "place-sstat",
              activities: ["USING_ESCALATOR"]
            },
            informed_entity
          )
        end)

      assert south_station_entities_count == 1
    end
  end

  describe "elevator and escalator" do
    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} =
        AccessibilityMapper.map_subscriptions(
          Map.merge(@params, %{"accessibility" => ["elevator", "escalator"]})
        )

      assert subscription.type == :accessibility
    end

    test "constructs subscription with 00:00:00 to 23:59:59 timeframe" do
      {:ok, [{subscription, _ie}]} =
        AccessibilityMapper.map_subscriptions(
          Map.merge(@params, %{"accessibility" => ["elevator", "escalator"]})
        )

      assert subscription.start_time == ~T[00:00:00]
      assert subscription.end_time == ~T[23:59:59]
    end

    test "constructs subscription with routes" do
      {:ok, [{_subscription, informed_entities}]} =
        AccessibilityMapper.map_subscriptions(
          Map.merge(@params, %{"accessibility" => ["elevator", "escalator"]})
        )

      red_line_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(%InformedEntity{facility_type: :elevator, route: "Red"}, informed_entity)
        end)

      assert red_line_entities_count == 1

      blue_line_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(%InformedEntity{facility_type: :elevator, route: "Blue"}, informed_entity)
        end)

      assert blue_line_entities_count == 0
    end

    test "constructs subscription with stops" do
      {:ok, [{_subscription, informed_entities}]} =
        AccessibilityMapper.map_subscriptions(
          Map.merge(@params, %{"accessibility" => ["elevator", "escalator"]})
        )

      north_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-north"}, informed_entity)
        end)

      assert north_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(%InformedEntity{facility_type: :elevator, stop: "place-sstat"}, informed_entity)
        end)

      assert south_station_entities_count == 1
    end
  end

  describe "build_subscription_transaction" do
    @params %{
      "accessibility" => ["elevator"],
      "stops" => ["place-north", "place-sstat"],
      "routes" => ["red"],
      "relevant_days" => ["weekday"]
    }

    test "it builds a multi struct to persist subscriptions and informed_entities" do
      user = insert(:user)
      {:ok, subscription_infos} = AccessibilityMapper.map_subscriptions(@params)

      multi =
        AccessibilityMapper.build_subscription_transaction(subscription_infos, user, user.id)

      result = Ecto.Multi.to_list(multi)

      assert {{:subscription, 0}, {:run, function}} = List.first(result)
      assert {{:new_informed_entity, 0, 0}, {:run, _}} = Enum.at(result, 1)

      {:ok, %{model: subscription}} = function.(nil)
      assert subscription.id != nil
    end
  end
end
