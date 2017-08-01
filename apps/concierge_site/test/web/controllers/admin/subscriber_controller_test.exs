defmodule ConciergeSite.Admin.SubscriberControllerTest do
  use ConciergeSite.ConnCase

  describe "admin user" do
    test "GET /admin/subscribers", %{conn: conn} do
      conn =
        :user
        |> insert(role: "customer_support")
        |> guardian_login(conn, :token, perms: %{default: Guardian.Permissions.max, admin: [:customer_support]})
        |> get(admin_subscriber_path(conn, :index))

      assert html_response(conn, 200) =~ "Subscribers"
    end
  end

  describe "regular user" do
    test "GET /admin/subscribers", %{conn: conn} do
      conn =
        :user
        |> insert(role: "user")
        |> guardian_login(conn)
        |> get(admin_subscriber_path(conn, :index))

      assert html_response(conn, 302) =~ "/login/new"
    end
  end

  describe "unauthenticated" do
    test "GET /admin/subscribers", %{conn: conn} do
      conn = get(conn, admin_subscriber_path(conn, :index))

      assert html_response(conn, 302) =~ "/login/new"
    end
  end
end
