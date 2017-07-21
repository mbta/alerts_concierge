defmodule AlertProcessor.Model.SubscriptionTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.Model.Subscription

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
  end
end
