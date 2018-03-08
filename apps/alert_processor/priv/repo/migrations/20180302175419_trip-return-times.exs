defmodule :"Elixir.AlertProcessor.Repo.Migrations.Trip-return-times" do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :return_start_time, :time, null: true
      add :return_end_time, :time, null: true
    end
  end
end
