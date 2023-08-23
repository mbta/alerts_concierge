defmodule AlertProcessor.Repo.Migrations.DropPasswordResetsTable do
  use Ecto.Migration

  def change do
    drop table(:password_resets)
  end
end
