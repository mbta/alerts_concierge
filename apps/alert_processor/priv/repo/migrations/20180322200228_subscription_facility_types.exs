defmodule Elixir.AlertProcessor.Repo.Migrations.Subscription_facility_types do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :facility_types, {:array, :string}, null: false, default: []
    end
  end
end
