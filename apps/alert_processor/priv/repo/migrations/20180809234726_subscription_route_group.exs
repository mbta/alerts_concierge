defmodule AlertProcessor.Repo.Migrations.SubscriptionRouteGroup do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add(:parent_id, :uuid)
    end
  end
end
