defmodule AlertProcessor.Repo.Migrations.AddUuidExtension do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\" WITH SCHEMA public;"
    alter table(:users) do
      modify :id, :uuid, default: fragment("uuid_generate_v4()")
      modify :inserted_at, :utc_datetime, default: fragment("now()")
      modify :updated_at, :utc_datetime, default: fragment("now()")
    end

    alter table(:subscriptions) do
      modify :id, :uuid, default: fragment("uuid_generate_v4()")
      modify :inserted_at, :utc_datetime, default: fragment("now()")
      modify :updated_at, :utc_datetime, default: fragment("now()")
    end

    alter table(:informed_entities) do
      modify :id, :uuid, default: fragment("uuid_generate_v4()")
      modify :inserted_at, :utc_datetime, default: fragment("now()")
      modify :updated_at, :utc_datetime, default: fragment("now()")
    end
  end

  def down do
    alter table(:users) do
      modify :id, :uuid, default: nil
      modify :inserted_at, :utc_datetime, default: nil
      modify :updated_at, :utc_datetime, default: nil
    end

    alter table(:subscriptions) do
      modify :id, :uuid, default: nil
      modify :inserted_at, :utc_datetime, default: nil
      modify :updated_at, :utc_datetime, default: nil
    end

    alter table(:informed_entities) do
      modify :id, :uuid, default: nil
      modify :inserted_at, :utc_datetime, default: nil
      modify :updated_at, :utc_datetime, default: nil
    end
    execute "DROP EXTENSION \"uuid-ossp\";"
  end
end
