defmodule AlertProcessor.Repo.Migrations.RemoveVacationsAndBlackoutsFromUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove(:vacation_start)
      remove(:vacation_end)
      remove(:do_not_disturb_start)
      remove(:do_not_disturb_end)
    end
  end

  def down do
    alter table(:users) do
      add(:vacation_start, :utc_datetime)
      add(:vacation_end, :utc_datetime)
      add(:do_not_disturb_start, :time)
      add(:do_not_disturb_end, :time)
    end
  end
end
