defmodule ConciergeSite.Admin.BoatLongMigrationController do
  use ConciergeSite.Web, :controller

  import Ecto.Query

  alias AlertProcessor.Model.Route
  alias AlertProcessor.Model.Subscription
  alias AlertProcessor.Repo

  @f1_route "Boat-F1"
  @f1_stop "Boat-Long"

  @eastboston_route "Boat-EastBoston"
  @eastboston_old_stop "Boat-Long"
  @eastboston_new_stop "Boat-Long-North-5B"
  @eastboston_new_stop_lat 42.36089
  @eastboston_new_stop_long -71.04964

  @lynn_route "Boat-Lynn"
  @lynn_old_stop "Boat-Long"
  @lynn_new_stop "Boat-Long-North-5C"
  @lynn_new_stop_lat 42.36095
  @lynn_new_stop_long -71.04925

  def index(conn, _params) do
    f1_count = subscription_count_for_route_and_stop(@f1_route, @f1_stop)

    eastboston_old_stop_count =
      subscription_count_for_route_and_stop(@eastboston_route, @eastboston_old_stop)

    eastboston_new_stop_count =
      subscription_count_for_route_and_stop(@eastboston_route, @eastboston_new_stop)

    lynn_old_stop_count = subscription_count_for_route_and_stop(@lynn_route, @lynn_old_stop)

    lynn_new_stop_count = subscription_count_for_route_and_stop(@lynn_route, @lynn_new_stop)

    render(conn, "index.html",
      f1_count: f1_count,
      eastboston_old_stop_count: eastboston_old_stop_count,
      eastboston_new_stop_count: eastboston_new_stop_count,
      lynn_old_stop_count: lynn_old_stop_count,
      lynn_new_stop_count: lynn_new_stop_count
    )
  end

  def migrate_boat_eastboston(conn, _params),
    do:
      migrate_for(
        conn,
        @eastboston_route,
        @eastboston_old_stop,
        @eastboston_new_stop,
        @eastboston_new_stop_lat,
        @eastboston_new_stop_long
      )

  def migrate_boat_lynn(conn, _params),
    do:
      migrate_for(
        conn,
        @lynn_route,
        @lynn_old_stop,
        @lynn_new_stop,
        @lynn_new_stop_lat,
        @lynn_new_stop_long
      )

  def delete_boat_eastboston(conn, _params),
    do: delete_for(conn, @eastboston_route, @eastboston_old_stop)

  def delete_boat_lynn(conn, _params),
    do: delete_for(conn, @lynn_route, @lynn_old_stop)

  @spec subscription_count_for_route_and_stop(Route.route_id(), Route.stop_id()) ::
          non_neg_integer()
  def subscription_count_for_route_and_stop(route, stop) do
    Repo.one(
      from(s in Subscription,
        where: s.route == ^route and (s.origin == ^stop or s.destination == ^stop),
        select: count(s.id)
      )
    )
  end

  @doc """
  Performs a mathematical operation on the last digit only of the given UUID,
  wrapping between 0 and f as needed.
  """
  @spec uuid_op(String.t(), (integer() -> integer())) :: String.t()
  def uuid_op(uuid, op) do
    last_digit = String.last(uuid)

    adjacent_last_digit =
      last_digit
      |> String.to_integer(16)
      |> Kernel.+(16)
      |> op.()
      |> Integer.to_string(16)
      |> String.last()
      |> String.downcase()

    String.slice(uuid, 0..(String.length(uuid) - 2)) <> adjacent_last_digit
  end

  defp migrate_for(conn, route, old_stop, new_stop, new_stop_lat, new_stop_long) do
    {:ok, flash} =
      Repo.transaction(
        fn ->
          subsciptions = subscriptions_by_route_and_id(route, old_stop)

          already_migrated_subscription_ids =
            route
            |> subscriptions_by_route_and_id(new_stop)
            |> Enum.map(& &1.id)

          new_subscriptions =
            Enum.map(subsciptions, fn subscription ->
              new_subscription(
                subscription,
                already_migrated_subscription_ids,
                old_stop,
                new_stop,
                new_stop_lat,
                new_stop_long
              )
            end)

          {new_subscriptions, already_migrated_subscriptions} =
            Enum.split_with(new_subscriptions, &match?(%Subscription{}, &1))

          new_subscription_count = length(new_subscriptions)
          already_mgrated_count = length(already_migrated_subscriptions)

          "Migrated #{new_subscription_count} subscriptions, #{already_mgrated_count} were already migrated."
        end,
        timeout: 60_000
      )

    conn
    |> put_flash(:info, flash)
    |> redirect(to: admin_boat_long_migration_path(conn, :index))
  end

  defp delete_for(conn, route, stop) do
    {count, _} = delete_subscriptions_by_route_and_id(route, stop)

    flash = "Deleted #{count} subscriptions."

    conn
    |> put_flash(:info, flash)
    |> redirect(to: admin_boat_long_migration_path(conn, :index))
  end

  @spec subscriptions_by_route_and_id(Route.route_id(), Route.stop_id()) :: [Subscription.t()]
  defp subscriptions_by_route_and_id(route, stop) do
    Repo.all(
      from(s in Subscription,
        where: s.route == ^route and (s.origin == ^stop or s.destination == ^stop)
      )
    )
  end

  @spec delete_subscriptions_by_route_and_id(Route.route_id(), Route.stop_id()) ::
          {non_neg_integer(), nil | [term()]}
  defp delete_subscriptions_by_route_and_id(route, stop) do
    Repo.delete_all(
      from(s in Subscription,
        where: s.route == ^route and (s.origin == ^stop or s.destination == ^stop)
      ),
      timeout: 60_000
    )
  end

  @spec new_subscription(
          Subscription.t(),
          [Subscription.id()],
          Route.stop_id(),
          Route.stop_id(),
          float(),
          float()
        ) ::
          Subscription.t() | :already_migrated
  defp new_subscription(
         %Subscription{id: old_id} = old_subscription,
         already_migrated_subscription_ids,
         old_stop,
         new_stop,
         new_stop_lat,
         new_stop_long
       ) do
    new_id = uuid_op(old_id, &(&1 + 1))

    if Enum.member?(already_migrated_subscription_ids, new_id) do
      :already_migrated
    else
      new_subscription = %Subscription{
        old_subscription
        | id: Ecto.UUID.cast!(new_id),
          inserted_at: nil,
          updated_at: nil
      }

      new_subscription =
        if new_subscription.origin == old_stop do
          %Subscription{
            new_subscription
            | origin: new_stop,
              origin_lat: new_stop_lat,
              origin_long: new_stop_long
          }
        else
          new_subscription
        end

      new_subscription =
        if new_subscription.destination == old_stop do
          %Subscription{
            new_subscription
            | destination: new_stop,
              destination_lat: new_stop_lat,
              destination_long: new_stop_long
          }
        else
          new_subscription
        end

      Repo.insert!(new_subscription)
    end
  end
end
