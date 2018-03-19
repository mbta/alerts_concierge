defmodule AlertProcessor.Model.TripTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{Trip, User, Subscription}

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)
  @base_attrs %{
    alert_priority_type: :low,
    relevant_days: [:monday],
    start_time: ~T[12:00:00],
    end_time: ~T[18:00:00],
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

  test "get_trips_by_user/1" do
    user = Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password})
    Repo.insert!(%Trip{user_id: user.id, alert_priority_type: :low, relevant_days: [:monday], start_time: ~T[12:00:00],
                       end_time: ~T[18:00:00], station_features: [:accessibility]})

    assert [trip] = Trip.get_trips_by_user(user.id)
    assert trip.user_id == user.id
    assert [] == Trip.get_trips_by_user("ba51f08c-ad36-4dd5-a81a-557168c42f51")
  end

  describe "delete/1" do
    test "returns `{:ok, Trip.t}` with valid trip", %{user: user, valid_attrs: valid_attrs} do
      trip =
        %Trip{}
        |> Trip.create_changeset(valid_attrs)
        |> Repo.insert!
      assert [%Trip{}] = Trip.get_trips_by_user(user.id)
      assert {:ok, %Trip{}} = Trip.delete(trip)
      assert [] = Trip.get_trips_by_user(user.id)
    end

    test "deletes a trip's subscriptions", %{user: user, valid_attrs: trip_attrs} do
      trip =
        %Trip{}
        |> Trip.create_changeset(trip_attrs)
        |> Repo.insert!()
      subscription_attrs = %{
        user_id: user.id,
        trip_id: trip.id,
        alert_priority_type: :low,
        start_time: ~T[12:00:00],
        end_time: ~T[18:00:00]
      }
      %Subscription{}
      |> Subscription.create_changeset(subscription_attrs)
      |> Repo.insert!()
      assert [_] = Repo.all(Subscription)
      Trip.delete(trip)
      assert [] = Repo.all(Subscription)
    end
  end

  test "find_by_id/1 returns trip for valid id" do
    trip = insert(:trip)
    found_trip = Trip.find_by_id(trip.id)
    assert found_trip.id == trip.id
  end

  describe "update/2" do
    test "returns valid changeset with valid params" do
      trip_details = %{
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[13:30:00],
        return_start_time: ~T[18:00:00],
        return_end_time: ~T[18:30:00],
        alert_time_difference_in_minutes: 60
      }
      trip = insert(:trip, trip_details)
      params = %{
        start_time: ~T[13:00:00],
        end_time: ~T[13:30:00],
        return_start_time: ~T[15:00:00],
        return_end_time: ~T[15:30:00],
        relevant_days: [:tuesday],
        alert_time_difference_in_minutes: 30
      }
      {:ok, %Trip{} = _} = Trip.update(trip, params)
      updated_trip = Trip.find_by_id(trip.id)
      assert updated_trip.start_time == ~T[13:00:00.000000]
      assert updated_trip.end_time == ~T[13:30:00.000000]
      assert updated_trip.return_start_time == ~T[15:00:00.000000]
      assert updated_trip.return_end_time == ~T[15:30:00.000000]
      assert updated_trip.relevant_days == [:tuesday]
      assert updated_trip.alert_time_difference_in_minutes == 30
    end

    test "errors if updated without any days" do
      trip = insert(:trip)
      params = %{relevant_days: []}
      assert {:error, %Ecto.Changeset{} = changeset} = Trip.update(trip, params)
      assert :relevant_days in Keyword.keys(changeset.errors)
    end

    test "errors if invalid alert_time_difference_in_minutes" do
      trip = insert(:trip)
      params = %{alert_time_difference_in_minutes: 10}
      assert {:error, %Ecto.Changeset{} = changeset} = Trip.update(trip, params)
      assert :alert_time_difference_in_minutes in Keyword.keys(changeset.errors)
    end
  end
end
