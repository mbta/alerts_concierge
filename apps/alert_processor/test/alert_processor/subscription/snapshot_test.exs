defmodule AlertProcessor.Subscription.SnapshotTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Repo, Model.Subscription}
  alias AlertProcessor.Subscription.{Snapshot, Mapper, BusMapper}

  describe "get_snapshots_by_datetime/2" do
    test "returns latest version that existed on the given date" do
      subscriber = insert(:user)
      {:ok, future_date, _} = DateTime.from_iso8601("2118-01-01T01:01:01Z")
      {:ok, date, _} = DateTime.from_iso8601("2017-07-11T01:01:01Z")
      {:ok, past_date, _} = DateTime.from_iso8601("2017-01-11T01:01:01Z")
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
        updated_at: date,
        relevant_days: [:saturday]
      })
      {:ok, future_updated_sub} = Subscription.update_subscription(updated_sub, %{
        updated_at: future_date,
        relevant_days: [:saturday, :sunday]
      })

      [original_version, updated_version, future_version] = PaperTrail.get_versions(future_updated_sub)
      insert_changeset = Ecto.Changeset.cast(original_version, %{inserted_at: past_date}, [:inserted_at])
      update_changeset = Ecto.Changeset.cast(updated_version, %{inserted_at: date}, [:inserted_at])
      future_changeset = Ecto.Changeset.cast(future_version, %{inserted_at: future_date}, [:inserted_at])

      Repo.update!(insert_changeset)
      Repo.update!(update_changeset)
      Repo.update!(future_changeset)

      [snapshot] = Snapshot.get_snapshots_by_datetime(subscriber, date)

      assert snapshot.subscription["relevant_days"] ==  ["saturday"]
    end

    test "fetches correct informed_entities for version" do
      params = %{
        "route" => "16 - 0",
        "relevant_days" => ["weekday", "saturday"],
        "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
        "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
        "return_start" => DateTime.from_naive!(~N[2017-07-20 18:00:00], "Etc/UTC"),
        "return_end" => DateTime.from_naive!(~N[2017-07-20 20:00:00], "Etc/UTC"),
        "alert_priority_type" => "low",
        "trip_type" => "one_way"
      }
      {:ok, future_date, _} = DateTime.from_iso8601("2118-01-01T01:01:01Z")
      user = insert(:user)
      {:ok, [info|_]} = BusMapper.map_subscription(params)
      multi = Mapper.build_subscription_transaction([info], user)
      Subscription.set_versioned_subscription(multi)

      [snapshot] = Snapshot.get_snapshots_by_datetime(user, future_date)

      [%{id: sub_id, informed_entities: [%{id: ie1_id}, %{id: ie2_id}, %{id: ie3_id}]}] =
        Repo.all(Subscription) |> Repo.preload(:informed_entities)

      assert %{
        subscription: %{"id" => ^sub_id},
        informed_entities: [%{"id" => ^ie3_id}, %{"id" => ^ie2_id}, %{"id" => ^ie1_id}]
      } = snapshot
    end
  end
end
