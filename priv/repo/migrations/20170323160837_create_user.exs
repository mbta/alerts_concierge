defmodule MbtaServer.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :phone_number, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
  end
end

