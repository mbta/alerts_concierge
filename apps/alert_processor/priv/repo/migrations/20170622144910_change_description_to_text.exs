defmodule AlertProcessor.Repo.Migrations.ChangeDescriptionToText do
  use Ecto.Migration

  def change do
    alter table(:notifications, primary_key: false) do
      modify :description, :text
    end
  end
end
