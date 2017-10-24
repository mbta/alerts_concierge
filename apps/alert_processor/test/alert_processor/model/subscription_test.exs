defmodule AlertProcessor.Model.SubscriptionTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{Subscription, InformedEntity}
  alias AlertProcessor.Subscription.{BusMapper, Mapper}

  @base_attrs %{
    alert_priority_type: :low,
    relevant_days: [:weekday],
    start_time: ~T[12:00:00],
    end_time: ~T[18:00:00]
  }

  setup do
    user = insert(:user)
    valid_attrs = Map.put(@base_attrs, :user_id, user.id)

    {:ok, user: user, valid_attrs: valid_attrs}
  end

  test "create_changeset/2 with valid parameters", %{valid_attrs: valid_attrs} do
    changeset = Subscription.create_changeset(%Subscription{}, valid_attrs)
    assert changeset.valid?
  end

  test "create_changeset/2 requires a user_id", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :user_id)
    changeset = Subscription.create_changeset(%Subscription{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 validates relevant days", %{valid_attrs: valid_attrs} do
    attrs = Map.put(valid_attrs, :relevant_days, [:garbage])
    changeset = Subscription.create_changeset(%Subscription{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 requires alert priority type", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :alert_priority_type)
    changeset = Subscription.create_changeset(%Subscription{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 validates alert priority type", %{valid_attrs: valid_attrs} do
    attrs = Map.put(valid_attrs, :alert_priority_type, :garbage)
    changeset = Subscription.create_changeset(%Subscription{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 validates that the user has at most one amenity", %{user: user, valid_attrs: valid_attrs} do
    amenity_entity = [
      %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"}
    ]

    :subscription
    |> build(user: user)
    |> weekday_subscription()
    |> amenity_subscription()
    |> Repo.preload(:informed_entities)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:informed_entities, amenity_entity)
    |> Repo.insert()

    attrs = Map.put(valid_attrs, :type, :amenity)
    changeset = Subscription.create_changeset(%Subscription{}, attrs)

    refute changeset.valid?
  end

  test "update_changeset/2 with valid parameters", %{valid_attrs: valid_attrs} do
    changeset = Subscription.update_changeset(%Subscription{}, valid_attrs)
    assert changeset.valid?
  end

  test "update_changeset/2 does not allow user_id", %{valid_attrs: valid_attrs} do
    changeset = Subscription.update_changeset(%Subscription{}, valid_attrs)
    refute Map.has_key?(changeset.changes, :user_id)
  end

  describe "timeframe map" do
    test "maps timeframe for weekday" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[18:00:00],
        relevant_days: [:weekday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        monday: %{start: 43_200, end: 64_800},
        tuesday: %{start: 43_200, end: 64_800},
        wednesday: %{start: 43_200, end: 64_800},
        thursday: %{start: 43_200, end: 64_800},
        friday: %{start: 43_200, end: 64_800}
      } == timeframe_map
    end

    test "maps timeframe for saturday" do
      subscription = %Subscription{
        start_time: ~T[10:00:00],
        end_time: ~T[16:00:00],
        relevant_days: [:saturday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        saturday: %{start: 36_000, end: 57_600}
      } == timeframe_map
    end

    test "maps timeframe for sunday" do
      subscription = %Subscription{
        start_time: ~T[08:00:00],
        end_time: ~T[14:00:00],
        relevant_days: [:sunday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        sunday: %{start: 28_800, end: 50_400}
      } == timeframe_map
    end

    test "maps timeframe for multiple relevant days" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[18:00:00],
        relevant_days: [:weekday, :saturday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        monday: %{start: 43_200, end: 64_800},
        tuesday: %{start: 43_200, end: 64_800},
        wednesday: %{start: 43_200, end: 64_800},
        thursday: %{start: 43_200, end: 64_800},
        friday: %{start: 43_200, end: 64_800},
        saturday: %{start: 43_200, end: 64_800}
      } == timeframe_map
    end

    test "maps timeframe to next timeframe for late night service" do
      subscription = %Subscription{
        start_time: ~T[01:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:weekday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        tuesday: %{start: 3600, end: 14_400},
        wednesday: %{start: 3600, end: 14_400},
        thursday: %{start: 3600, end: 14_400},
        friday: %{start: 3600, end: 14_400},
        saturday: %{start: 3600, end: 14_400}
      } == timeframe_map
    end

    test "maps timeframe to next timeframe for late night service for saturday" do
      subscription = %Subscription{
        start_time: ~T[01:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:saturday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        sunday: %{start: 3600, end: 14_400}
      } == timeframe_map
    end

    test "maps timeframe to next timeframe for late night service for sunday" do
      subscription = %Subscription{
        start_time: ~T[01:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:sunday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        monday: %{start: 3600, end: 14_400}
      } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for weekday" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:weekday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        monday: %{start: 43_200, end: 86_399},
        tuesday: %{start: 43_200, end: 14_400},
        wednesday: %{start: 43_200, end: 14_400},
        thursday: %{start: 43_200, end: 14_400},
        friday: %{start: 43_200, end: 14_400},
        saturday: %{start: 0, end: 14_400}
      } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for saturday" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:saturday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        saturday: %{start: 43_200, end: 86_399},
        sunday: %{start: 0, end: 14_400}
      } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for sunday" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:sunday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        sunday: %{start: 43_200, end: 86_399},
        monday: %{start: 0, end: 14_400}
      } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for multiple relevant days" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:weekday, :saturday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        monday: %{start: 43_200, end: 86_399},
        tuesday: %{start: 43_200, end: 14_400},
        wednesday: %{start: 43_200, end: 14_400},
        thursday: %{start: 43_200, end: 14_400},
        friday: %{start: 43_200, end: 14_400},
        saturday: %{start: 43_200, end: 14_400},
        sunday: %{start: 0, end: 14_400}
      } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for all relevant days" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:weekday, :saturday, :sunday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        monday: %{start: 43_200, end: 14_400},
        tuesday: %{start: 43_200, end: 14_400},
        wednesday: %{start: 43_200, end: 14_400},
        thursday: %{start: 43_200, end: 14_400},
        friday: %{start: 43_200, end: 14_400},
        saturday: %{start: 43_200, end: 14_400},
        sunday: %{start: 43_200, end: 14_400}
      } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for all relevant days different order" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:saturday, :weekday, :sunday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        monday: %{start: 43_200, end: 14_400},
        tuesday: %{start: 43_200, end: 14_400},
        wednesday: %{start: 43_200, end: 14_400},
        thursday: %{start: 43_200, end: 14_400},
        friday: %{start: 43_200, end: 14_400},
        saturday: %{start: 43_200, end: 14_400},
        sunday: %{start: 43_200, end: 14_400}
      } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for all relevant days different order still doesnt matter" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:sunday, :saturday, :weekday]
      }
      timeframe_map = Subscription.timeframe_map(subscription)
      assert %{
        monday: %{start: 43_200, end: 14_400},
        tuesday: %{start: 43_200, end: 14_400},
        wednesday: %{start: 43_200, end: 14_400},
        thursday: %{start: 43_200, end: 14_400},
        friday: %{start: 43_200, end: 14_400},
        saturday: %{start: 43_200, end: 14_400},
        sunday: %{start: 43_200, end: 14_400}
      } == timeframe_map
    end
  end

  describe "set_versioned_subscription/1" do
    @params %{
      "routes" => ["16 - 0"],
      "relevant_days" => ["weekday", "saturday"],
      "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
      "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
      "return_start" => DateTime.from_naive!(~N[2017-07-20 18:00:00], "Etc/UTC"),
      "return_end" => DateTime.from_naive!(~N[2017-07-20 20:00:00], "Etc/UTC"),
      "alert_priority_type" => "low",
      "trip_type" => "one_way"
    }

    test "creates subscription and informed entities from Ecto.Multi" do
      user = insert(:user)
      {:ok, [info|_]} = BusMapper.map_subscription(@params)
      multi = Mapper.build_subscription_transaction([info], user, user.id)
      Subscription.set_versioned_subscription(multi)

      assert [sub|_] = Subscription |> Repo.all() |> Repo.preload(:informed_entities)
      refute length(sub.informed_entities) == 0
    end

    test "associates versions of informed entities with version of subscription" do
      user = insert(:user)
      {:ok, [info|_]} = BusMapper.map_subscription(@params)
      multi = Mapper.build_subscription_transaction([info], user, user.id)
      Subscription.set_versioned_subscription(multi)

      [sub|_] = Subscription |> Repo.all() |> Repo.preload(:informed_entities)
      sub_version = PaperTrail.get_version(sub)
      informed_entity_version_ids = Enum.map(sub.informed_entities, fn(ie) ->
        PaperTrail.get_version(ie).id
      end)

      assert MapSet.new(sub_version.meta["informed_entity_version_ids"]) ==
        MapSet.new(informed_entity_version_ids)
    end
  end

  describe "update_subscription" do
    test "updates subscription" do
      user = insert(:user)
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      assert {:ok, subscription} = Subscription.update_subscription(subscription, %{"alert_priority_type" => :low}, user.id)
      assert subscription.alert_priority_type == :low
    end

    test "does not update subscription" do
      user = insert(:user)
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      assert {:error, changeset} = Subscription.update_subscription(subscription, %{"alert_priority_type" => :super_high}, user.id)
      refute changeset.valid?
    end

    test "initiated by admin" do
      admin_user = insert(:user, role: "application_administration")
      user = insert(:user)

      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      assert {:ok, subscription} = Subscription.update_subscription(subscription, %{"alert_priority_type" => :low}, admin_user.id)
      assert subscription.alert_priority_type == :low
      assert %{
        item_id: item_id,
        item_type: "Subscription",
        origin: "admin:update-subscription",
        meta: %{
          "owner" => owner_id,
        }
      } = PaperTrail.get_version(subscription)
      assert item_id == subscription.id
      assert owner_id == user.id
    end
  end

  describe "delete_subscription" do
    test "deletes subscription" do
      user = insert(:user)
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      assert {:ok, subscription} = Subscription.delete_subscription(subscription, user.id)
      assert nil == Repo.get(Subscription, subscription.id)
    end

    test "initiated by admin" do
      admin_user = insert(:user, role: "application_administration")
      user = insert(:user)

      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      assert {:ok, subscription} = Subscription.delete_subscription(subscription, admin_user.id)
      assert nil == Repo.get(Subscription, subscription.id)
      assert %{
        item_id: item_id,
        item_type: "Subscription",
        origin: "admin:delete-subscription",
        meta: %{
          "owner" => owner_id,
        }
      } = PaperTrail.get_version(subscription)
      assert item_id == subscription.id
      assert owner_id == user.id
    end
  end

  describe "full_mode_subscription_types_for_user" do
    test "matches subscriptions without informed entities for user" do
      user = insert(:user, role: "application_administration")
      insert(:admin_subscription, type: :bus, user: user)
      insert(:admin_subscription, type: :subway, user: user)
      assert Subscription.full_mode_subscription_types_for_user(user) == [:bus, :subway]
    end

    test "does not match subscriptions with informed entities for user" do
      user = insert(:user, role: "application_administration")
      insert(:admin_subscription, type: :bus, user: user)
      :admin_subscription
      |> build(type: :subway, user: user)
      |> subway_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, subway_subscription_entities())
      |> Repo.insert()

      assert Subscription.full_mode_subscription_types_for_user(user) == [:bus]
    end
  end

  describe "create_full_mode_subscriptions" do
    test "creates new full mode subscriptions" do
      user = insert(:user, role: "application_administration")
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, select: count(s.id)) == 0
      Subscription.create_full_mode_subscriptions(user, %{"bus" => "true", "commuter_rail" => "true", "ferry" => "false", "subway" => "true"})
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, where: s.type == "bus", select: count(s.id)) == 1
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, where: s.type == "commuter_rail", select: count(s.id)) == 1
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, where: s.type == "subway", select: count(s.id)) == 1
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, where: s.type == "ferry", select: count(s.id)) == 0
    end

    test "creates full mode subscription in correct format" do
      user = insert(:user, role: "application_administration")
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, select: count(s.id)) == 0
      Subscription.create_full_mode_subscriptions(user, %{"bus" => "false", "commuter_rail" => "false", "ferry" => "false", "subway" => "true"})
      [subscription] = Repo.all(from s in Subscription, preload: [:informed_entities], where: s.user_id == ^user.id)
      assert %Subscription{
        informed_entities: [],
        relevant_days: [:weekday, :saturday, :sunday],
        start_time: ~T[00:00:00.000000],
        end_time: ~T[23:59:59.000000],
        alert_priority_type: :low,
        type: :subway
      } = subscription
      assert %{
        item_id: item_id,
        item_type: "Subscription",
        origin: "admin:create-full-mode-subscription",
        meta: %{
          "owner" => owner_id,
        }
      } = PaperTrail.get_version(subscription)
      assert item_id == subscription.id
      assert owner_id == user.id
    end

    test "does not create new if already exists" do
      user = insert(:user, role: "application_administration")
      subscription = insert(:admin_subscription, user: user, type: "bus")
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, select: count(s.id)) == 1
      Subscription.create_full_mode_subscriptions(user, %{"bus" => "true", "commuter_rail" => "true", "ferry" => "false", "subway" => "true"})
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, where: s.type == "bus", select: s.id) == subscription.id
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, where: s.type == "commuter_rail", select: count(s.id)) == 1
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, where: s.type == "subway", select: count(s.id)) == 1
    end

    test "deletes if already exists" do
      user = insert(:user, role: "application_administration")
      subscription = insert(:admin_subscription, user: user, type: "bus")
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, select: count(s.id)) == 1
      Subscription.create_full_mode_subscriptions(user, %{"bus" => "false", "commuter_rail" => "false", "ferry" => "false", "subway" => "false"})
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, where: s.type == "bus", select: count(s.id)) == 0
      assert Repo.get(Subscription, subscription.id) == nil
      assert %{
        item_id: item_id,
        item_type: "Subscription",
        origin: "admin:delete-full-mode-subscription",
        meta: %{
          "owner" => owner_id
        }
      } = PaperTrail.get_version(subscription)
      assert item_id == subscription.id
      assert owner_id == user.id
    end

    test "does not allow other roles to create subscriptions" do
      user = insert(:user, role: "customer_support")
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, select: count(s.id)) == 0
      assert :ok = Subscription.create_full_mode_subscriptions(user, %{"bus" => "true", "commuter_rail" => "true", "ferry" => "false", "subway" => "true"})
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, select: count(s.id)) == 0
    end

    test "returns :ok if params are not passed in" do
      user = insert(:user, role: "customer_support")
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, select: count(s.id)) == 0
      assert :ok = Subscription.create_full_mode_subscriptions(user, nil)
      assert Repo.one(from s in Subscription, where: s.user_id == ^user.id, select: count(s.id)) == 0
    end
  end

  describe "relevant_days_string" do
    test "converts weekday subscription relevant days into human friendly iodata" do
      subscription = :subscription |> build() |> weekday_subscription()
      relevant_days_string = Subscription.relevant_days_string(subscription)
      assert IO.iodata_to_binary(relevant_days_string) == "Weekdays"
    end

    test "converts weekday, saturday subscription relevant days into human friendly iodata" do
      subscription = :subscription |> build() |> saturday_subscription() |> weekday_subscription()
      relevant_days_string = Subscription.relevant_days_string(subscription)
      assert IO.iodata_to_binary(relevant_days_string) == "Weekdays, Saturdays"
    end

    test "converts weekday, saturday, sunday subscription relevant days into human friendly iodata" do
      subscription = :subscription |> build() |> sunday_subscription() |> saturday_subscription() |> weekday_subscription()
      relevant_days_string = Subscription.relevant_days_string(subscription)
      assert IO.iodata_to_binary(relevant_days_string) == "Weekdays, Saturdays, Sundays"
    end
  end

  describe "route_count/1" do
    test "returns the number of route entities in a subscription" do
      user = build(:user)
      {:ok, subscription} =
        :subscription
        |> build(user: user)
        |> weekday_subscription()
        |> bus_subscription()
        |> Repo.preload(:informed_entities)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:informed_entities, bus_subscription_entities())
        |> Repo.insert()

      assert 1 == Subscription.route_count(subscription)
    end

    test "returns the number of route entities in a subscription for multiple" do
      user = build(:user)
      {:ok, subscription} =
        :subscription
        |> build(user: user)
        |> weekday_subscription()
        |> bus_subscription()
        |> Repo.preload(:informed_entities)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:informed_entities, bus_subscription_entities() ++ bus_subscription_entities("87"))
        |> Repo.insert()

      assert 2 == Subscription.route_count(subscription)
    end

    test "treats same route in opposite direction as separate route" do
      user = build(:user)
      {:ok, subscription} =
        :subscription
        |> build(user: user)
        |> weekday_subscription()
        |> bus_subscription()
        |> Repo.preload(:informed_entities)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:informed_entities, Enum.uniq(bus_subscription_entities("87", :inbound) ++ bus_subscription_entities("87", :outbound)))
        |> Repo.insert()

      assert 2 == Subscription.route_count(subscription)
    end
  end
end
