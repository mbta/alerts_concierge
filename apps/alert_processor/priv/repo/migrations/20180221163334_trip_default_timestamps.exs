defmodule AlertProcessor.Repo.Migrations.TripDefaultTimestamps do
  use Ecto.Migration

  def up do
    alter table(:trips) do
      modify :inserted_at, :utc_datetime, default: fragment("now()")
      modify :updated_at, :utc_datetime, default: fragment("now()")
    end
  end

  def down do
    alter table(:trips) do
      modify :inserted_at, :utc_datetime, default: nil
      modify :updated_at, :utc_datetime, default: nil
    end
  end
end
