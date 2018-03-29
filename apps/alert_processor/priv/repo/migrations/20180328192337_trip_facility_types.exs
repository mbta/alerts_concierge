defmodule AlertProcessor.Repo.Migrations.TripFacilityTypes do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :facility_types, {:array, :string}, null: false, default: []
      remove :station_features
    end
  end
end
