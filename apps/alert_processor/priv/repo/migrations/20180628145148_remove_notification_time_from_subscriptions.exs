defmodule AlertProcessor.Repo.Migrations.RemoveNotificationTimeFromSubscriptions do
  use Ecto.Migration

  def up do
    alter table(:subscriptions) do
      remove :notification_time
    end
  end

  def down do
    alter table(:subscriptions) do
      add :notification_time, :time
    end
  end
end
