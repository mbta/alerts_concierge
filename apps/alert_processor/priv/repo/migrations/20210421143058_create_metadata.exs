defmodule AlertProcessor.Repo.Migrations.CreateMetadata do
  use Ecto.Migration

  def change do
    create table(:metadata, primary_key: false) do
      add :id, :string, primary_key: true
      add :data, :map, default: %{}, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
