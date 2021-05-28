defmodule AlertProcessor.Repo.Migrations.AddEmailRejectionToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:email_rejection_status, :string)
    end
  end
end
