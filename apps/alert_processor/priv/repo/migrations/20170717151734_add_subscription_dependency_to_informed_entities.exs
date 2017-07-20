defmodule MbtaServer.Repo.Migrations.AddSubscriptionDependencyToInformedEntities do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE informed_entities DROP CONSTRAINT informed_entities_subscription_id_fkey"
    alter table(:informed_entities) do
      modify :subscription_id, references(:subscriptions, type: :uuid, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE informed_entities DROP CONSTRAINT informed_entities_subscription_id_fkey"
    alter table(:informed_entities) do
      modify :subscription_id, references(:subscriptions, type: :uuid)
    end
  end
end
