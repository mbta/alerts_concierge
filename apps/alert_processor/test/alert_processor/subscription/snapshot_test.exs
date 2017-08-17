defmodule AlertProcessor.Subscription.SnapshotTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Repo, Model.Subscription, Subscription.Snapshot}

  describe "get_snapshots_by_datetime/2" do
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

      assert snapshot["relevant_days"] ==  ["saturday"]
    end
  end
end
