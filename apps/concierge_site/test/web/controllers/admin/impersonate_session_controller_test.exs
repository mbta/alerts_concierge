defmodule Admin.ImpersonateSessionControllerTest do
  use ConciergeSite.ConnCase

  @customer_support_token_params %{
    default: Guardian.Permissions.max,
    admin: [:customer_support]
  }

  describe "admin user" do
    setup :insert_admin

    test "POST /admin/impersonate_sessions", %{conn: conn, user: user} do
      user_to_impersonate = insert(:user)
      params = %{"user_id" => user_to_impersonate.id}

      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> post(admin_impersonate_session_path(conn, :create, params))

      assert html_response(conn, 302), "/my-subscriptions"
    end
  end

  describe "regular_user" do
    setup :insert_user

    test "POST /admin/impersonate_sessions", %{conn: conn, user: user} do
      user_to_impersonate = insert(:user)
      params = %{"user_id" => user_to_impersonate.id}

      conn =
        user
        |> guardian_login(conn)
        |> post(admin_impersonate_session_path(conn, :create, params))

      assert html_response(conn, 403) =~ "Forbidden"
    end
  end

  describe "unauthenticated" do
    test "POST /admin/impersonate_sessions", %{conn: conn} do
      user_to_impersonate = insert(:user)
      params = %{"user_id" => user_to_impersonate.id}
      conn = post(conn, admin_impersonate_session_path(conn, :create, params))

      assert html_response(conn, 302) =~ "login/new"
    end
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
  end

  defp insert_admin(_context) do
    {:ok, [user: insert(:user, role: "customer_support")]}
  end
end
