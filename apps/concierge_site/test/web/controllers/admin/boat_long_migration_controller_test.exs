defmodule BoatLongMigrationControllerTest do
  use ConciergeSite.ConnCase, async: true

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
      insert(:subscription, route: "Boat-F1", origin: "Boat-Long", destination: "Boat-Hingham")
      insert(:subscription, route: "Boat-F1", origin: "Boat-Hingham", destination: "Boat-Long")
      insert(:subscription, route: "Boat-F1")

      insert(:subscription, route: "Boat-EastBoston", origin: "Boat-Long", destination: "Boat-Lewis")
      insert(:subscription, route: "Boat-EastBoston", origin: "Boat-Lewis", destination: "Boat-Long")
      insert(:subscription, route: "Boat-EastBoston")

      insert(:subscription, route: "Boat-EastBoston", origin: "Boat-Long-North-5B", destination: "Boat-Lewis")
      insert(:subscription, route: "Boat-EastBoston", origin: "Boat-Lewis", destination: "Boat-Long-North-5B")

      insert(:subscription, route: "Boat-Lynn", origin: "Boat-Long", destination: "Boat-Blossom")
      insert(:subscription, route: "Boat-Lynn", origin: "Boat-Blossom", destination: "Boat-Long")
      insert(:subscription, route: "Boat-Lynn")

      insert(:subscription, route: "Boat-Lynn", origin: "Boat-Long-North-5C", destination: "Boat-Blossom")
      insert(:subscription, route: "Boat-Lynn", origin: "Boat-Blossom", destination: "Boat-Long-North-5C")

      conn = get(conn, admin_boat_long_migration_path(conn, :index))

      assert html_response(conn, 200) =~ ~r/<dd data-testid=\"boat-f1-boat-long-count\">2<\/dd>/
      assert html_response(conn, 200) =~ ~r/<dd data-testid=\"boat-eastboston-boat-long-count\">2<\/dd>/
      assert html_response(conn, 200) =~ ~r/<dd data-testid=\"boat-eastboston-boat-long-north-5b-count\">2<\/dd>/
      assert html_response(conn, 200) =~ ~r/<dd data-testid=\"boat-lynn-boat-long-count\">2<\/dd>/
      assert html_response(conn, 200) =~ ~r/<dd data-testid=\"boat-lynn-boat-long-north-5c-count\">2<\/dd>/
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = get(conn, admin_boat_long_migration_path(conn, :index))

      assert redirected_to(conn) == "/trips"
    end
  end
end
