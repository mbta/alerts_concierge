defmodule AlertProcessor.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :alert_id, :string
      add :last_modified, :utc_datetime
      add :data, :map

      timestamps(type: :utc_datetime)
    end

    create index(:alerts, [:last_modified])
    create unique_index(:alerts, [:alert_id])
  end
end
