defmodule AlertProcessor.Repo.Migrations.AddReminderBooleanToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :reminder?, :boolean, default: false, null: false
    end
  end
end
