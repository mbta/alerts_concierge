defmodule AlertProcessor.Repo.Migrations.DropUuidOsspExtension do
  use Ecto.Migration

  def up do
    # Use the built-in function for generating UUIDs instead of the version from the uuid-ossp extension. Previously, earlier migrations used the function `uuid_generate_v4`. Those migrations have now been changed in code so databases migrated from scratch will reference that function, but this migration will update existing database schemas.
    alter table(:users) do
      modify :id, :uuid, default: fragment("gen_random_uuid()")
    end
    alter table(:subscriptions) do
      modify :id, :uuid, default: fragment("gen_random_uuid()")
    end
    alter table(:informed_entities) do
      modify :id, :uuid, default: fragment("gen_random_uuid()")
    end
    alter table(:password_resets, primary_key: false) do
      modify :id, :uuid, default: fragment("gen_random_uuid()")
    end
    alter table(:trips, primary_key: false) do
      modify :id, :uuid, default: fragment("gen_random_uuid()")
    end

    # The uuid-ossp extension used to be required for generating UUIDs, but now the `gen_random_uuid` function is built in to Postgres starting with version 13 so we no longer need this extension.
    execute "DROP EXTENSION IF EXISTS \"uuid-ossp\";"
  end
end
