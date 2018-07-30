defmodule AlertProcessor.Repo.Migrations.AddPauseField do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add(:paused, :boolean, default: false)
    end
  end
end
