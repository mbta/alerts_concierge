defmodule AlertProcessor.Repo.Migrations.EditSubscriptionTripIDToDeleteAllOnDelete do
  use Ecto.Migration

  def up do
    drop constraint(:subscriptions, "subscriptions_trip_id_fkey")
    alter table(:subscriptions) do
      modify :trip_id, references(:trips, type: :uuid, on_delete: :delete_all)
    end
  end

  def down do
    drop constraint(:subscriptions, "subscriptions_trip_id_fkey")
    alter table(:subscriptions) do
      modify :trip_id, references(:trips, type: :uuid)
    end
  end
end
