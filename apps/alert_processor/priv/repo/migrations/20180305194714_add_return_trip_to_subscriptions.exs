defmodule AlertProcessor.Repo.Migrations.AddReturnTripToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :return_trip, :boolean, default: false
    end
  end
end
