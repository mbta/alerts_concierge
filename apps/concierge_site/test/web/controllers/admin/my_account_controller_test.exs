defmodule ConciergeSite.Admin.MyAccountControllerTest do
  use ConciergeSite.ConnCase

  @customer_support_token_params %{
    default: Guardian.Permissions.max,
    admin: [:customer_support]
  }

  describe "admin user" do
    setup :insert_admin

    test "GET /admin/my-account/edit", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> get(admin_my_account_path(conn, :edit))

      assert html_response(conn, 200) =~ "Account"
    end
  end

  describe "regular user" do
    setup :insert_user

    test "GET /admin/my-account/edit", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn)
        |> get(admin_my_account_path(conn, :edit))

      assert html_response(conn, 403) =~ "Forbidden"
    end
  end

  describe "unauthenticated" do
    test "GET /admin/my-account/edit", %{conn: conn} do
      conn = get(conn, admin_my_account_path(conn, :edit))

      assert html_response(conn, 302) =~ "/login/new"
    end
  end

  defp insert_admin(_context) do
    {:ok, [user: insert(:user, role: "customer_support")]}
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
  end
end
