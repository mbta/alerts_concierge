defmodule :"Elixir.AlertProcessor.Repo.Migrations.Trip-roundtrip" do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :roundtrip, :boolean, default: false, null: false
    end
  end
end
