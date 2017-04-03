defmodule MbtaServer.Repo.Migrations.AddRoleToUser do
  use Ecto.Migration

  def change do
    alter table(:users, primary_key: false) do
      add :role, :string, null: false, default: "user"
    end
  end
end
