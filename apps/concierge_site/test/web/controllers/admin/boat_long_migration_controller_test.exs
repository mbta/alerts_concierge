defmodule BoatLongMigrationControllerTest do
  use ConciergeSite.ConnCase, async: true

  alias ConciergeSite.Admin.BoatLongMigrationController

  @f1_route "Boat-F1"
  @f1_stop "Boat-Long"
  @f1_other_stop "Boat-Hingham"

  @eastboston_route "Boat-EastBoston"
  @eastboston_old_stop "Boat-Long"
  @eastboston_new_stop "Boat-Long-North-5B"
  @eastboston_other_stop "Boat-Lewis"

  @lynn_route "Boat-Lynn"
  @lynn_old_stop "Boat-Long"
  @lynn_new_stop "Boat-Long-North-5C"
  @lynn_other_stop "Boat-Blossom"

  setup %{conn: conn} do
    user = insert(:user, role: "admin")
    conn = guardian_login(user, conn)

    {:ok, user: user, conn: conn}
  end

  describe "index" do
    test "renders successfully", %{conn: conn} do
      conn = get(conn, admin_boat_long_migration_path(conn, :index))
      assert html_response(conn, 200) =~ "Boat-Long Subscription Migration"
    end

    test "counts subscriptions", %{conn: conn} do
      insert(:subscription, route: @f1_route, origin: @f1_stop, destination: @f1_other_stop)
      insert(:subscription, route: @f1_route, origin: @f1_other_stop, destination: @f1_stop)
      insert(:subscription, route: @f1_route)

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_old_stop,
        destination: @eastboston_other_stop
      )

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_other_stop,
        destination: @eastboston_old_stop
      )

      insert(:subscription, route: @eastboston_route)

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_new_stop,
        destination: @eastboston_other_stop
      )

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_other_stop,
        destination: @eastboston_new_stop
      )

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_old_stop,
        destination: @lynn_other_stop
      )

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_other_stop,
        destination: @lynn_old_stop
      )

      insert(:subscription, route: @lynn_route)

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_new_stop,
        destination: @lynn_other_stop
      )

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_other_stop,
        destination: @lynn_new_stop
      )

      conn = get(conn, admin_boat_long_migration_path(conn, :index))

      assert html_response(conn, 200) =~ ~r/<dd data-testid=\"f1-long-count\">2<\/dd>/

      assert html_response(conn, 200) =~
               ~r/<dd data-testid=\"eastboston-old-stop-count\">2<\/dd>/

      assert html_response(conn, 200) =~
               ~r/<dd data-testid=\"eastboston-new-stop-count\">2<\/dd>/

      assert html_response(conn, 200) =~ ~r/<dd data-testid=\"lynn-old-stop-count\">2<\/dd>/

      assert html_response(conn, 200) =~
               ~r/<dd data-testid=\"lynn-new-stop-count\">2<\/dd>/
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = get(conn, admin_boat_long_migration_path(conn, :index))

      assert redirected_to(conn) == "/trips"
    end
  end

  describe "migrate_boat_eastboston" do
    test "makes a copy of each subscription substituting the new stop", %{conn: conn} do
      starting_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_old_stop
        )

      starting_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_new_stop
        )

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_old_stop,
        destination: @eastboston_other_stop
      )

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_other_stop,
        destination: @eastboston_old_stop
      )

      insert(:subscription, route: @eastboston_route)

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_new_stop,
        destination: @eastboston_other_stop
      )

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_other_stop,
        destination: @eastboston_new_stop
      )

      before_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_old_stop
        )

      before_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_new_stop
        )

      assert before_old_stop_count - starting_old_stop_count == 2
      assert before_new_stop_count - starting_new_stop_count == 2

      conn = post(conn, admin_boat_long_migration_path(conn, :migrate_boat_eastboston))
      assert redirected_to(conn) == admin_boat_long_migration_path(conn, :index)

      after_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_old_stop
        )

      after_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_new_stop
        )

      assert after_old_stop_count - before_old_stop_count == 0
      assert after_new_stop_count - before_new_stop_count == 2
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = post(conn, admin_boat_long_migration_path(conn, :migrate_boat_eastboston))

      assert redirected_to(conn) == "/trips"
    end
  end

  describe "migrate_boat_lynn" do
    test "makes a copy of each subscription substituting the new stop", %{conn: conn} do
      starting_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_old_stop
        )

      starting_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_new_stop
        )

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_old_stop,
        destination: @lynn_other_stop
      )

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_other_stop,
        destination: @lynn_old_stop
      )

      insert(:subscription, route: @lynn_route)

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_new_stop,
        destination: @lynn_other_stop
      )

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_other_stop,
        destination: @lynn_new_stop
      )

      before_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_old_stop
        )

      before_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_new_stop
        )

      assert before_old_stop_count - starting_old_stop_count == 2
      assert before_new_stop_count - starting_new_stop_count == 2

      conn = post(conn, admin_boat_long_migration_path(conn, :migrate_boat_lynn))
      assert redirected_to(conn) == admin_boat_long_migration_path(conn, :index)

      after_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_old_stop
        )

      after_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_new_stop
        )

      assert after_old_stop_count - before_old_stop_count == 0
      assert after_new_stop_count - before_new_stop_count == 2
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = post(conn, admin_boat_long_migration_path(conn, :migrate_boat_lynn))

      assert redirected_to(conn) == "/trips"
    end
  end

  describe "delete_boat_eastboston" do
    test "deletes old subscriptions and notification deliveries", %{conn: conn} do
      starting_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_old_stop
        )

      starting_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_new_stop
        )

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_old_stop,
        destination: @eastboston_other_stop
      )

      insert(:subscription,
        route: @eastboston_route,
        origin: @eastboston_new_stop,
        destination: @eastboston_other_stop
      )

      before_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_old_stop
        )

      before_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_new_stop
        )

      assert before_old_stop_count - starting_old_stop_count == 1
      assert before_new_stop_count - starting_new_stop_count == 1

      conn = post(conn, admin_boat_long_migration_path(conn, :delete_boat_eastboston))
      assert redirected_to(conn) == admin_boat_long_migration_path(conn, :index)
      assert get_flash(conn, :info) == "Deleted 1 subscriptions."

      after_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_old_stop
        )

      after_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @eastboston_route,
          @eastboston_new_stop
        )

      assert after_old_stop_count - before_old_stop_count == -1
      assert after_new_stop_count - before_new_stop_count == 0
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = post(conn, admin_boat_long_migration_path(conn, :delete_boat_eastboston))

      assert redirected_to(conn) == "/trips"
    end
  end

  describe "delete_boat_lynn" do
    test "deletes old subscriptions and notification deliveries", %{conn: conn} do
      starting_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_old_stop
        )

      starting_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_new_stop
        )

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_old_stop,
        destination: @lynn_other_stop
      )

      insert(:subscription,
        route: @lynn_route,
        origin: @lynn_new_stop,
        destination: @lynn_other_stop
      )

      before_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_old_stop
        )

      before_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_new_stop
        )

      assert before_old_stop_count - starting_old_stop_count == 1
      assert before_new_stop_count - starting_new_stop_count == 1

      conn = post(conn, admin_boat_long_migration_path(conn, :delete_boat_lynn))
      assert redirected_to(conn) == admin_boat_long_migration_path(conn, :index)
      assert get_flash(conn, :info) == "Deleted 1 subscriptions."

      after_old_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_old_stop
        )

      after_new_stop_count =
        BoatLongMigrationController.subscription_count_for_route_and_stop(
          @lynn_route,
          @lynn_new_stop
        )

      assert after_old_stop_count - before_old_stop_count == -1
      assert after_new_stop_count - before_new_stop_count == 0
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = post(conn, admin_boat_long_migration_path(conn, :delete_boat_lynn))

      assert redirected_to(conn) == "/trips"
    end
  end
end
