defmodule AlertProcessor.Repo.Migrations.AddUrlToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :url, :string
    end
  end
end
