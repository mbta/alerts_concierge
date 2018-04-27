defmodule AlertProcessor.Repo.Migrations.CascadeDeletesFromUserTable do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE notifications DROP CONSTRAINT notifications_user_id_fkey;"
    execute "ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;"

    execute "ALTER TABLE subscriptions DROP CONSTRAINT subscriptions_user_id_fkey;"
    execute "ALTER TABLE subscriptions ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;"

    execute "ALTER TABLE trips DROP CONSTRAINT trips_user_id_fkey;"
    execute "ALTER TABLE trips ADD CONSTRAINT trips_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;"

    execute "ALTER TABLE versions DROP CONSTRAINT versions_originator_id_fkey;"
    execute "ALTER TABLE versions ADD CONSTRAINT versions_originator_id_fkey FOREIGN KEY (originator_id) REFERENCES users(id) ON DELETE CASCADE;"
  end

  def down do
    execute "ALTER TABLE notifications DROP CONSTRAINT notifications_user_id_fkey;"
    execute "ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);"

    execute "ALTER TABLE subscriptions DROP CONSTRAINT subscriptions_user_id_fkey;"
    execute "ALTER TABLE subscriptions ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);"

    execute "ALTER TABLE trips DROP CONSTRAINT trips_user_id_fkey;"
    execute "ALTER TABLE trips ADD CONSTRAINT trips_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);"

    execute "ALTER TABLE versions DROP CONSTRAINT versions_originator_id_fkey;"
    execute "ALTER TABLE versions ADD CONSTRAINT versions_originator_id_fkey FOREIGN KEY (originator_id) REFERENCES users(id);"
  end
end
