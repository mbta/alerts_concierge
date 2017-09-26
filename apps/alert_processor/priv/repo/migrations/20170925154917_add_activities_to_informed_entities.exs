defmodule AlertProcessor.Repo.Migrations.AddActivitiesToInformedEntities do
  use Ecto.Migration

  def change do
    alter table(:informed_entities, primary_key: false) do
      add :activities, {:array, :string}, null: false, default: []
    end
  end
end
