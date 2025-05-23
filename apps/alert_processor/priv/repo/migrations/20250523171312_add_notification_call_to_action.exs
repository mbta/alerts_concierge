defmodule AlertProcessor.Repo.Migrations.AddNotificationCallToAction do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add(:call_to_action, :string)
    end
  end
end
