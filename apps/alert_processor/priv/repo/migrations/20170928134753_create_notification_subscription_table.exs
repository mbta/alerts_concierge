defmodule AlertProcessor.Repo.Migrations.CreateNotificationSubscriptionTable do
  use Ecto.Migration

  def change do
    create table(:notification_subscriptions) do
      add :notification_id, :binary_id, null: false
      add :subscription_id, :binary_id, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notification_subscriptions, [:notification_id])
  end
end
