defmodule AlertProcessor.Repo.Migrations.SubscriptionChanges do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :trip_id, references(:trips, type: :uuid)
      add :rank, :smallint
      add :notification_time, :time
    end
  end
end
