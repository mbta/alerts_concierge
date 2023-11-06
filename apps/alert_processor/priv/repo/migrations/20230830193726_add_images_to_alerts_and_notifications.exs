defmodule AlertProcessor.Repo.Migrations.AddImagesToAlerts do
  use Ecto.Migration

  def change do
    alter table(:alerts) do
      add(:image_url, :string)
      add(:image_alternative_text, :string)
    end
    alter table(:notifications) do
      add(:image_url, :string)
      add(:image_alternative_text, :string)
    end
  end
end
