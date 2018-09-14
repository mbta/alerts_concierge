defmodule AlertProcessor.Repo.Migrations.RemoveSeverityFilter do
  use Ecto.Migration

  def up do
    alter table(:subscriptions) do
      remove(:alert_priority_type)
    end

    alter table(:trips) do
      remove(:alert_priority_type)
    end
  end

  def down do
    alter table(:subscriptions) do
      add(:alert_priority_type, :string, null: false)
    end

    alter table(:trips) do
      add(:alert_priority_type, :string, null: false)
    end
  end
end
