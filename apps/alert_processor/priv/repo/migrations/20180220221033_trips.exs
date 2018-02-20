defmodule AlertProcessor.Repo.Migrations.Trips do
  use Ecto.Migration

  def change do
    create table(:trips, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid), null: false
      add :alert_priority_type, :string, null: false
      add :relevant_days, {:array, :string}, null: false, default: []
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :notification_time, :time, null: false
      add :station_features, {:array, :string}, null: false, default: []
      add :inserted_at, :utc_datetime, null: false
    end

    create index(:trips, [:user_id])
  end
end
