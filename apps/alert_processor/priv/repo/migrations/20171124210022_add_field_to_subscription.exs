defmodule AlertProcessor.Repo.Migrations.AddFieldToSubscription do
  use Ecto.Migration

  def change do
    alter table(:subscriptions, primary_key: false) do
      add :route, :string, null: true
      add :direction_id, :smallint, null: true
      add :origin_lat, :float, null: true
      add :origin_long, :float, null: true
      add :destination_lat, :float, null: true
      add :destination_long, :float, null: true
    end
  end
end
