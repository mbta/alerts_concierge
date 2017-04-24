defmodule MbtaServer.Repo.Migrations.AddAlertPriorityTypeToSubscription do
  use Ecto.Migration

  def change do
    alter table(:subscriptions, primary_key: false) do
      add :alert_priority_type, :string, null: false
    end
  end
end
