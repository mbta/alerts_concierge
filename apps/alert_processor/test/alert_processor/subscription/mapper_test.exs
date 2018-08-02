defmodule AlertProcessor.Subscription.MapperTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Subscription.{Mapper, BikeStorageMapper}
  alias AlertProcessor.Model.{Subscription, InformedEntity}

  @params %{
    "stops" => ["place-north", "place-sstat"],
    "relevant_days" => ["weekday"]
  }

  describe "build_subscription_update_transaction" do
    test "it builds a multi struct to persist subscriptions and informed_entities" do
      subscription =
        insert(
          :subscription,
          informed_entities: [%InformedEntity{stop: "place-north", facility_type: :bike_storage}]
        )

      user = insert(:user)
      {:ok, subscription_infos} = BikeStorageMapper.map_subscriptions(@params)

      multi =
        Mapper.build_subscription_update_transaction(subscription, subscription_infos, user.id)

      result = Ecto.Multi.to_list(multi)

      assert [
               {{:new_informed_entity, 0}, {:run, ie_fun}},
               {{:new_informed_entity, 1}, {:run, _}},
               {{:remove_current, 0}, {:run, remove_current_fun}},
               {{:subscription}, {:run, sub_fun}}
             ] = result

      {:ok, %{model: %InformedEntity{} = ie}} = ie_fun.(nil)
      assert ie.id != nil
      {:ok, %{model: %InformedEntity{} = current}} = remove_current_fun.(nil)
      assert current.id != nil
      {:ok, %{model: %Subscription{} = sub}} = sub_fun.(nil)
      assert sub.id == subscription.id
    end
  end
end
