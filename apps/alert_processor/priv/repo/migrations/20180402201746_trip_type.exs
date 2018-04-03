defmodule AlertProcessor.Repo.Migrations.TripType do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :trip_type, :string, null: false, default: "commute"
    end
  end
end
