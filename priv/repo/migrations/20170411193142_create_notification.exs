defmodule MbtaServer.Repo.Migrations.CreateNotification do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :uuid)
      add :alert_id, :string, null: false
      add :email, :string
      add :phone_number, :string
      add :header, :string
      add :message, :string
      add :send_after, :utc_datetime

      timestamps(type: :utc_datetime)
    end
  end
end
