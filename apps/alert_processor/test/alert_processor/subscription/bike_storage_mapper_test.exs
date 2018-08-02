defmodule AlertProcessor.Subscription.BikeStorageMapperTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Subscription.BikeStorageMapper
  alias AlertProcessor.Model.InformedEntity

  @params %{
    "stops" => ["place-north", "place-sstat"],
    "relevant_days" => ["weekday"]
  }

  describe "bike_storage" do
    test "creates expected entities" do
      {:ok, [{_subscription, informed_entities}]} = BikeStorageMapper.map_subscriptions(@params)

      north_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :bike_storage,
              stop: "place-north",
              activities: ["STORE_BIKE"]
            },
            informed_entity
          )
        end)

      assert north_station_entities_count == 1

      south_station_entities_count =
        Enum.count(informed_entities, fn informed_entity ->
          match?(
            %InformedEntity{
              facility_type: :bike_storage,
              stop: "place-sstat",
              activities: ["STORE_BIKE"]
            },
            informed_entity
          )
        end)

      assert south_station_entities_count == 1
    end
  end

  describe "build_subscription_transaction" do
    @params %{
      "stops" => ["place-north", "place-sstat"],
      "relevant_days" => ["weekday"]
    }

    test "it builds a multi struct to persist subscriptions and informed_entities" do
      user = insert(:user)
      {:ok, subscription_infos} = BikeStorageMapper.map_subscriptions(@params)
      multi = BikeStorageMapper.build_subscription_transaction(subscription_infos, user, user.id)
      result = Ecto.Multi.to_list(multi)

      assert {{:subscription, 0}, {:run, function}} = List.first(result)
      assert {{:new_informed_entity, 0, 0}, {:run, _}} = Enum.at(result, 1)

      {:ok, %{model: subscription}} = function.(nil)
      assert subscription.id != nil
    end
  end
end
