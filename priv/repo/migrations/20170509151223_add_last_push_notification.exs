defmodule MbtaServer.Repo.Migrations.AddLastPushNotification do
  use Ecto.Migration

  def change do
    alter table(:notifications, primary_key: false) do
      add :last_push_notification, :utc_datetime
    end
  end
end
