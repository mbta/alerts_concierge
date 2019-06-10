defmodule AlertProcessor.Repo.Migrations.UpdateAdminFlagName do
  use Ecto.Migration

  def up do
    rename(table(:subscriptions), :admin?, to: :is_admin)
  end

  def down do
    rename(table(:subscriptions), :is_admin, to: :admin?)
  end
end
