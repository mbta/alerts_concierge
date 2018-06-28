defmodule AlertProcessor.Repo.Migrations.AddTravelStartAndEndTimesToSubscriptions do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :travel_start_time, :time
      add :travel_end_time, :time
    end
  end
end
