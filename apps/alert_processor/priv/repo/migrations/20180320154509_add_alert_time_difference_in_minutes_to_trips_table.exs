defmodule AlertProcessor.Repo.Migrations.AddAlertTimeDifferenceInMinutesToTripsTable do
  use Ecto.Migration

  def up do
    alter table(:trips) do
      add :alert_time_difference_in_minutes, :integer, null: false, default: 60
      remove :notification_time
    end

    drop_trip_subscriptions_update_trigger()
  end

  def down do
    alter table(:trips) do
      add :notification_time, :time
      remove :alert_time_difference_in_minutes
    end

    create_trip_subscriptions_update_trigger()
  end

  defp drop_trip_subscriptions_update_trigger do
    execute "DROP TRIGGER IF EXISTS set_subscriptions_to_trip_trigger ON trips;"
    execute "DROP FUNCTION IF EXISTS set_subscriptions_to_trip();"
  end

  defp create_trip_subscriptions_update_trigger do
    execute """
    CREATE OR REPLACE FUNCTION set_subscriptions_to_trip() RETURNS TRIGGER AS $$
      BEGIN
        UPDATE subscriptions SET alert_priority_type = NEW.alert_priority_type,
                                 relevant_days = NEW.relevant_days,
                                 start_time = NEW.start_time,
                                 end_time = NEW.end_time,
                                 notification_time = NEW.notification_time
        WHERE trip_id = NEW.id;
        RETURN NEW;
      END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER set_subscriptions_to_trip_trigger
      AFTER UPDATE ON trips
      FOR EACH ROW EXECUTE PROCEDURE set_subscriptions_to_trip();
    """
  end
end
