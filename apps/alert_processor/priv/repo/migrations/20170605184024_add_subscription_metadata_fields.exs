defmodule AlertProcessor.Repo.Migrations.AddSubscriptionMetadataFields do
  use Ecto.Migration

  def change do
    alter table(:subscriptions) do
      add :origin, :string
      add :destination, :string
      add :type, :string
    end
  end
end
