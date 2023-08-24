defmodule AlertProcessor.Repo.Migrations.RemoveEncryptedPasswordFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :encrypted_password
    end
  end
end
