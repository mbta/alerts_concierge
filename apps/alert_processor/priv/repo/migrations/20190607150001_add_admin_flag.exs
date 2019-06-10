defmodule AlertProcessor.Repo.Migrations.AddAdminFlag do
  use Ecto.Migration

  def up do
    alter table(:subscriptions) do
      add(:admin?, :boolean, default: false, null: false)
    end
  end

  def down do
    alter table(:subscriptions) do
      remove(:admin?)
    end
  end
end
