defmodule AlertProcessor.Repo.Migrations.RemoveAmberAlertsFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :amber_alert_opt_in
    end
  end
end
