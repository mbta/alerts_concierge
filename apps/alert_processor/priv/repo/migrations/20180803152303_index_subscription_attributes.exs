defmodule AlertProcessor.Repo.Migrations.IndexSubscriptionAttributes do
  use Ecto.Migration

  def up do
    execute("CREATE INDEX subscriptions_route_ix ON subscriptions (route) WHERE paused = false;")

    execute(
      "CREATE INDEX subscriptions_origin_ix ON subscriptions (origin) WHERE paused = false;"
    )

    execute(
      "CREATE INDEX subscriptions_destination_ix ON subscriptions (destination) WHERE paused = false;"
    )

    execute(
      "CREATE INDEX subscriptions_route_type_ix ON subscriptions (route_type) WHERE paused = false;"
    )
  end

  def down do
    execute("DROP INDEX subscriptions_route_ix;")
    execute("DROP INDEX subscriptions_origin_ix;")
    execute("DROP INDEX subscriptions_destination_ix;")
    execute("DROP INDEX subscriptions_route_type_ix;")
  end
end
