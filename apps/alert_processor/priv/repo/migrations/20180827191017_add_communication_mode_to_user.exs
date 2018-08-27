defmodule AlertProcessor.Repo.Migrations.AddCommunicationModeToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:communication_mode, :string, null: false, default: "email")
    end
  end
end
