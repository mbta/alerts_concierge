defmodule AlertProcessor.Repo.Migrations.AddSubscriptionIdsToNotification do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :subscription_ids, {:array, :string}
    end
  end
end
