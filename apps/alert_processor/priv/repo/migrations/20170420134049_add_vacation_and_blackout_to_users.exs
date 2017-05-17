defmodule MbtaServer.Repo.Migrations.AddVacationAndBlackoutToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :vacation_start, :utc_datetime
      add :vacation_end, :utc_datetime
      add :do_not_disturb_start, :time
      add :do_not_disturb_end, :time
    end
  end
end
