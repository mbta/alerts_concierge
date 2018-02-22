defmodule AlertProcessor.Model.TripTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.Model.Trip

  @base_attrs %{
    alert_priority_type: :low,
    relevant_days: [:monday],
    start_time: ~T[12:00:00],
    end_time: ~T[18:00:00],
    notification_time: ~T[11:00:00],
    station_features: [:accessibility]
  }

  setup do
    user = insert(:user)
    valid_attrs = Map.put(@base_attrs, :user_id, user.id)

    {:ok, user: user, valid_attrs: valid_attrs}
  end

  test "create_changeset/2 with valid parameters", %{valid_attrs: valid_attrs} do
    changeset = Trip.create_changeset(%Trip{}, valid_attrs)

    assert changeset.valid?
  end

  test "create_changeset/2 requires a user_id", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :user_id)
    changeset = Trip.create_changeset(%Trip{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 validates relevant days", %{valid_attrs: valid_attrs} do
    attrs = Map.put(valid_attrs, :relevant_days, [:not_a_day])
    changeset = Trip.create_changeset(%Trip{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 requires at least one relevant day", %{valid_attrs: valid_attrs} do
    attrs = Map.put(valid_attrs, :relevant_days, [])
    changeset = Trip.create_changeset(%Trip{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 validates alert priority type", %{valid_attrs: valid_attrs} do
    attrs = Map.put(valid_attrs, :alert_priority_type, :not_a_priority_type)
    changeset = Trip.create_changeset(%Trip{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 allows empty station features list", %{valid_attrs: valid_attrs} do
    attrs = Map.put(valid_attrs, :station_features, [])
    changeset = Trip.create_changeset(%Trip{}, attrs)

    assert changeset.valid?
  end

  test "create_changeset/2 validates station features", %{valid_attrs: valid_attrs} do
    attrs = Map.put(valid_attrs, :alert_priority_type, [:not_a_station_feature])
    changeset = Trip.create_changeset(%Trip{}, attrs)

    refute changeset.valid?
  end
end
