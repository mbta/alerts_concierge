defmodule MbtaServer.Repo.Migrations.AddSubscriptionsTable do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :uuid)
      add :alert_types, {:array, :string}, default: []
      add :travel_days, {:array, :string}, default: []
      add :priority, :string, null: false
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:subscriptions, [:user_id])
    create index(:subscriptions, [:priority])
  end
end

