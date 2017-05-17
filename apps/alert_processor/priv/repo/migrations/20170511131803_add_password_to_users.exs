defmodule MbtaServer.Repo.Migrations.AddPasswordToUsers do
  use Ecto.Migration

  def change do
    alter table(:users, primary_key: false) do
      add :encrypted_password, :string, null: false
    end
  end
end
