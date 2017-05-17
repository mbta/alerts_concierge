defmodule MbtaServer.Repo.Migrations.AddInformedEntitiesTable do
  use Ecto.Migration

  def change do
    create table(:informed_entities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :subscription_id, references(:subscriptions, type: :uuid)
      add :direction_id, :integer
      add :facility, :string
      add :route, :string
      add :route_type, :integer
      add :stop, :string
      add :trip, :string

      timestamps(type: :utc_datetime)
    end

    create index(:informed_entities, [:subscription_id])
  end
end
