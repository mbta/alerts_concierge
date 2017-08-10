defmodule ConciergeSite.LayoutViewTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.LayoutView

  describe "admin_user?/1" do
    test "returns true if the user is an administrator" do
      admin = insert(:user, role: "application_administration")

      assert LayoutView.admin_user?(admin) == true
    end

    test "returns false if the user is not an administrator" do
      admin = insert(:user, role: "user")

      assert LayoutView.admin_user?(admin) == false
    end
  end

  describe "active_nav_class/2" do
    test "returns 'nav-active' for nav bar class if the current page matches the link",
         %{conn: conn} do
      conn = Map.put(conn, :path_info, ["admin", "subscribers"])

      assert LayoutView.active_nav_class(conn, "subscribers") == "nav-active"
    end

    test "returns empty string for nav bar class if the current page matches the link",
         %{conn: conn} do
      conn = Map.put(conn, :path_info, ["admin", "subscribers"])

      assert LayoutView.active_nav_class(conn, "admin_users") == ""
    end
  end

  describe "breadcrumbs/1" do
    test "returns a list of records for breadcrumb if in admin path",
         %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_info, ["admin", "subscribers"])
        |> Map.put(:request_path, "/admin/subscribers")

      assert LayoutView.breadcrumbs(conn) == [%{title: "Subscribers", path: "/admin/subscribers"}]
    end

    test "returns an empty list for breadcrumb if not in admin path",
         %{conn: conn} do
      conn = Map.put(conn, :path_info, ["my-subscriptions"])

      assert LayoutView.breadcrumbs(conn) == []
    end
  end
end
