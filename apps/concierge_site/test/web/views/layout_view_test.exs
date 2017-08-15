defmodule ConciergeSite.LayoutViewTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.LayoutView

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

  describe "impersonation_banner/2" do
    test "admin impersonating another user", %{conn: conn} do
      admin = insert(:user, role: "application_administration")
      user = insert(:user)

      html =
        user
        |> guardian_login(conn, :access, perms: %{default: Guardian.Permissions.max}, imp: admin.id)
        |> get("/my-account/edit")
        |> LayoutView.impersonation_banner(user)

      {:safe, banner} = html
      content = List.flatten(banner)

      assert Enum.member?(content, "You are logged in on behalf of #{user.email}.")
      assert Enum.member?(content, "Sign Out and Return to MBTA Admin")
    end

    test "user signed in but no impersonation", %{conn: conn} do
      user = insert(:user)

      html =
        user
        |> guardian_login(conn)
        |> get("/my-account/edit")
        |> LayoutView.impersonation_banner(user)

      assert is_nil(html)
    end

    test "no session", %{conn: conn} do
      assert is_nil(LayoutView.impersonation_banner(conn, nil))
    end
  end
end
