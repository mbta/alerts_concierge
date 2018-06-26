defmodule AlertProcessor.Repo.Migrations.CreateNotificationsAlertIDIndex do
  use Ecto.Migration

  def change do
    create index(:notifications, [:alert_id])
  end
end
