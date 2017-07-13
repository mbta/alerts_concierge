defmodule MbtaServer.Repo.Migrations.AddPasswordResetsTable do
  use Ecto.Migration

  def change do
    create table(:password_resets, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("uuid_generate_v4()")
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all)
      add :expired_at, :utc_datetime
      add :redeemed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:password_resets, [:user_id])
  end
end
