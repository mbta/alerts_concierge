defmodule AlertProcessor.Repo.Migrations.AddRouteTypeToSubscription do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :route_type, :integer
    end
  end
end
