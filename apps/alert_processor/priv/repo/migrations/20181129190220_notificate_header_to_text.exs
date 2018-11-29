defmodule AlertProcessor.Repo.Migrations.NotificateHeaderToText do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      modify :header, :text
    end
  end
end
