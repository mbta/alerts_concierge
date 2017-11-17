defmodule AlertProcessor.Subscription.SnapshotTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Repo, Model.Subscription}
  alias AlertProcessor.Subscription.{Snapshot, Mapper,
    BusMapper, CommuterRailMapper, CommuterRailParams}
  alias ConciergeSite.Subscriptions.CommuterRailParams

  describe "get_snapshots_by_datetime/2" do
    test "returns latest version that existed on the given date" do
      subscriber = build(:user) |> PaperTrail.insert!
      {:ok, future_date, _} = DateTime.from_iso8601("2118-01-01T01:01:01Z")
      {:ok, date, _} = DateTime.from_iso8601("2017-07-11T01:01:01Z")
      {:ok, past_date, _} = DateTime.from_iso8601("2017-01-11T01:01:01Z")
      sub_params = params_for(
        :subscription,
        user: subscriber,
        updated_at: past_date,
        inserted_at: past_date,
        relevant_days: [:sunday],
        type: :bus
      )
      create_changeset = Subscription.create_changeset(%Subscription{}, sub_params)
      inserted_sub = PaperTrail.insert!(create_changeset)
      {:ok, updated_sub} = Subscription.update_subscription(inserted_sub, %{
        updated_at: date,
        relevant_days: [:saturday]
      }, subscriber.id)
      {:ok, future_updated_sub} = Subscription.update_subscription(updated_sub, %{
        updated_at: future_date,
        relevant_days: [:saturday, :sunday]
      }, subscriber.id)

      user_version = PaperTrail.get_version(subscriber)
      [original_version, updated_version, future_version] = PaperTrail.get_versions(future_updated_sub)
      insert_changeset = Ecto.Changeset.cast(original_version, %{inserted_at: past_date}, [:inserted_at])
      update_changeset = Ecto.Changeset.cast(updated_version, %{inserted_at: date}, [:inserted_at])
      future_changeset = Ecto.Changeset.cast(future_version, %{inserted_at: future_date}, [:inserted_at])
      user_changeset = Ecto.Changeset.cast(user_version, %{inserted_at: date}, [:inserted_at])

      Repo.update!(insert_changeset)
      Repo.update!(update_changeset)
      Repo.update!(future_changeset)
      Repo.update!(user_changeset)

      {:ok, [subscription]} = Snapshot.get_snapshots_by_datetime(subscriber, date)

      assert %Subscription{} = subscription
      assert subscription.relevant_days == [:saturday]
      assert subscription.user.email == subscriber.email
    end

    test "fetches correct informed_entities for version" do
      params = %{
        "routes" => ["16 - 0"],
        "relevant_days" => ["weekday", "saturday"],
        "departure_start" => ~T[12:00:00],
        "departure_end" => ~T[14:00:00],
        "return_start" => ~T[18:00:00],
        "return_end" => ~T[20:00:00],
        "alert_priority_type" => "low",
        "trip_type" => "one_way"
      }
      {:ok, future_date, _} = DateTime.from_iso8601("2118-01-01T01:01:01Z")
      user = build(:user) |> PaperTrail.insert!
      {:ok, [info|_]} = BusMapper.map_subscription(params)
      multi = Mapper.build_subscription_transaction([info], user, user.id)
      Subscription.set_versioned_subscription(multi)

      {:ok, [subscription]} = Snapshot.get_snapshots_by_datetime(user, future_date)

      [%{informed_entities: [%{id: ie1_id}, %{id: ie2_id}, %{id: ie3_id}]}] =
        Subscription |> Repo.all() |> Repo.preload(:informed_entities)

      assert MapSet.new([ie1_id, ie2_id, ie3_id]) == MapSet.new(Enum.map(subscription.informed_entities, &(&1.id)))
    end

    test "fetches informed_entities for correct version when multiple exist" do
      {:ok, past_date, _} = DateTime.from_iso8601("2008-01-01T01:01:01Z")
      {:ok, future_date, _} = DateTime.from_iso8601("2108-01-01T01:01:01Z")
      {:ok, date, _} = DateTime.from_iso8601("2018-01-01T01:01:01Z")

      user = build(:user) |> PaperTrail.insert!
      sub_params = %{
        "origin" => "place-north",
        "destination" => "Anderson/ Woburn",
        "trips" => ["123"],
        "return_trips" => [],
        "relevant_days" => ["weekday"],
        "departure_start" => ~T[12:00:00],
        "departure_end" => ~T[14:00:00],
        "return_start" => ~T[18:00:00],
        "return_end" => ~T[20:00:00],
        "alert_priority_type" => "low",
        "amenities" => ["elevator"]
      }

      {:ok, info} = CommuterRailMapper.map_subscriptions(sub_params)
      multi = Mapper.build_subscription_transaction(info, user, user.id)
      Subscription.set_versioned_subscription(multi)
      Repo.update_all(PaperTrail.Version, set: [inserted_at: past_date])

      assert Snapshot.get_snapshots_by_datetime(user, date) == Snapshot.get_snapshots_by_datetime(user, future_date)

      # Update Subscription
      update_params = %{
        "alert_priority_type" => "high",
        "trips" => ["341"]
      }

      Subscription
      |> Repo.all
      |> Repo.preload(:informed_entities)
      |> Repo.preload(:user)
      |> Enum.each(fn(sub) ->
        {:ok, params} = CommuterRailParams.prepare_for_update_changeset(sub, update_params)
        multi = CommuterRailMapper.build_update_subscription_transaction(sub, params, user.id)
        Subscription.set_versioned_subscription(multi)
      end)

      # Set update versions to future date
      subs = Subscription |> Repo.all() |> Repo.preload(:informed_entities)

      Enum.each(subs, fn(sub) ->
        sub_version = PaperTrail.get_version(sub)
        sub_changeset = Ecto.Changeset.cast(sub_version, %{inserted_at: future_date}, [:inserted_at])
        Repo.update!(sub_changeset)
        Enum.each(sub.informed_entities, fn(ie) ->
          ie_version = PaperTrail.get_version(ie)
          ie_changeset = Ecto.Changeset.cast(ie_version, %{inserted_at: future_date}, [:inserted_at])
          Repo.update!(ie_changeset)
        end)
      end)

      refute Snapshot.get_snapshots_by_datetime(user, date) == Snapshot.get_snapshots_by_datetime(user, future_date)
    end
  end
end
