defmodule AlertProcessor.Repo.Migrations.AddDescriptionAndServiceEffectToNotifications do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :service_effect, :string
      add :description, :string
      remove :message
    end
  end
end
