defmodule MbtaServer.Repo.Migrations.AddSubscriptionsTable do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :uuid)

      timestamps(type: :utc_datetime)
    end

    create index(:subscriptions, [:user_id])
  end
end
