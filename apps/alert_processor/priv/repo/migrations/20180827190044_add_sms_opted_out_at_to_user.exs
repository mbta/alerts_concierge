defmodule AlertProcessor.Repo.Migrations.AddSmsOptedOutAtToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:sms_opted_out_at, :utc_datetime)
    end
  end
end
