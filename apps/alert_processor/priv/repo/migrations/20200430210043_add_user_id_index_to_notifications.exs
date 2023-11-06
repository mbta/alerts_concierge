defmodule AlertProcessor.Repo.Migrations.AddUserIdIndexToNotifications do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:notifications, [:user_id], concurrently: true)
  end
end
