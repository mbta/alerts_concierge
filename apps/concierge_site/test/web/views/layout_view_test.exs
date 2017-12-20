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

    test "renders breadcrumbs for Create a new alert subscriptions path",
         %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_info, ["subscriptions", "new"])
        |> Map.put(:request_path, "/subscriptions/new")

      assert LayoutView.breadcrumbs(conn) == [%{title: "New Subscriptions", path: "/subscriptions/new"}]
    end

    test "renders breadcrumbs diagnostics", %{conn: conn} do
      id = "abc123"
      conn =
        conn
        |> Map.put(:path_info, ["admin", "subscription_search"])
        |> Map.put(:request_path, "/admin/subscription_search/#{id}/new")

      assert LayoutView.breadcrumbs(conn) == [
        %{title: "Subscription Search", path: "/admin/subscription_search/#{id}/new"}
      ]
    end

    test "renders breadcrumbs for login path", %{conn: conn} do
      conn = conn
      |> Map.put(:path_info, ["login", "new"])
      |> Map.put(:request_path, "/login/new")

      assert LayoutView.breadcrumbs(conn) == [%{path: "/login/new", title: "Sign In"}]
    end

    test "renders breadcrumbs for reset password path", %{conn: conn} do
      conn = conn
      |> Map.put(:path_info, ["reset-password", "new"])
      |> Map.put(:request_path, "/reset-password/new")

      assert LayoutView.breadcrumbs(conn) == [%{path: "/reset-password/new", title: "Reset Password"}]
    end

    test "renders breadcrumbs for intro path", %{conn: conn} do
      conn = conn
      |> Map.put(:path_info, ["intro"])
      |> Map.put(:request_path, "/intro")

      assert LayoutView.breadcrumbs(conn) == [%{path: "/intro", title: "Create Account"}]
    end

    test "renders breadcrumbs for account path", %{conn: conn} do
      conn = conn
      |> Map.put(:path_info, ["account", "new"])
      |> Map.put(:request_path, "/account/new")

      assert LayoutView.breadcrumbs(conn) == [%{path: "/account/new", title: "Get Started"}]
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
