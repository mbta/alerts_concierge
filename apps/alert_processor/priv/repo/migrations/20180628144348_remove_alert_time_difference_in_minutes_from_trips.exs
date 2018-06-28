defmodule AlertProcessor.Repo.Migrations.RemoveAlertTimeDifferenceInMinutesFromTrips do
  use Ecto.Migration

  def up do
    alter table(:trips) do
      remove :alert_time_difference_in_minutes
    end
  end

  def down do
    alter table(:trips) do
      add :alert_time_difference_in_minutes, :integer, null: false, default: 60
    end
  end
end
