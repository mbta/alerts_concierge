defmodule AlertProcessor.Repo.Migrations.CreateSavedQueries do
  use Ecto.Migration

  def change do
    create table(:saved_queries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :label, :text, null: false
      add :query, :text, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
