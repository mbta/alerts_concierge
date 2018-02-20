defmodule AlertProcessor.Repo.Migrations.DigestPreference do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :digest_opt_in, :boolean, default: true, null: false
    end
  end
end
