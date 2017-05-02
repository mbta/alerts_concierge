defmodule MbtaServer.Repo.Migrations.AddTimeframeInfoToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions, primary_key: false) do
      add :relevant_days, {:array, :string}, null: false, default: []

      add :start_time, :time, null: false
      add :end_time, :time, null: false
    end
  end
end
