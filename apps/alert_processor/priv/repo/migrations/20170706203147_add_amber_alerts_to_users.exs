defmodule AlertProcessor.Repo.Migrations.AddAmberAlertsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :amber_alert_opt_in, :boolean, default: true
    end
  end
end
