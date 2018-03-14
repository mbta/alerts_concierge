defmodule AlertProcessor.Repo.Migrations.AddClosedTimestampToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications, primary_key: false) do
      add :closed_timestamp, :utc_datetime
    end
  end
end
