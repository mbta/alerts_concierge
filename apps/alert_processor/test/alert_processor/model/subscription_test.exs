defmodule AlertProcessor.Model.SubscriptionTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.Model.{Subscription, InformedEntity}

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

  describe "update_subscription" do
    test "updates subscription" do
      user = insert(:user)
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      assert {:ok, subscription} = Subscription.update_subscription(subscription, %{"alert_priority_type" => :low})
      assert subscription.alert_priority_type == :low
    end

    test "does not update subscription" do
      user = insert(:user)
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      assert {:error, changeset} = Subscription.update_subscription(subscription, %{"alert_priority_type" => :super_high})
      refute changeset.valid?
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

      assert {:ok, subscription} = Subscription.delete_subscription(subscription)
      assert nil == Repo.get(Subscription, subscription.id)
    end
  end

  describe "get_versions_by_date/2" do
    test "returns latest version that existed on the given date" do
      subscriber = insert(:user)
      {:ok, future_date} = NaiveDateTime.from_iso8601("2118-01-01T01:01:01")
      {:ok, date} = NaiveDateTime.from_iso8601("2017-07-11T01:01:01")
      {:ok, past_date} = NaiveDateTime.from_iso8601("2017-01-11T01:01:01")
      sub_params = params_for(
        :subscription,
        user: subscriber,
        updated_at: past_date,
        inserted_at: past_date,
        relevant_days: [:sunday]
      )
      create_changeset = Subscription.create_changeset(%Subscription{}, sub_params)
      inserted_sub = PaperTrail.insert!(create_changeset)
      {:ok, updated_sub} = Subscription.update_subscription(inserted_sub, %{
        updated_at: date
      })
      {:ok, future_updated_sub} = Subscription.update_subscription(updated_sub, %{
        updated_at: future_date
      })

      # update papertrail version dates
      [original_version, updated_version, future_version] = PaperTrail.get_versions(future_updated_sub)
      insert_changeset = Ecto.Changeset.cast(original_version, %{inserted_at: past_date}, [:inserted_at])
      update_changeset = Ecto.Changeset.cast(updated_version, %{inserted_at: date}, [:inserted_at])
      future_changeset = Ecto.Changeset.cast(future_version, %{inserted_at: future_date}, [:inserted_at])

      Repo.update!(insert_changeset)
      Repo.update!(update_changeset)
      Repo.update!(future_changeset)

      [original, updated] = Subscription.get_versions_by_date(subscriber, date)

      assert original.id == original_version.id
      assert updated.id == updated_version.id
    end
  end
end
