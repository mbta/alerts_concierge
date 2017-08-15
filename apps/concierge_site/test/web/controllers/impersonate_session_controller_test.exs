defmodule ImpersonateSessionControllerTest do
  use ConciergeSite.ConnCase

  describe "admin user" do
    setup :insert_admin

    test "DELETE /admin/impersonate_sessions", %{conn: conn, admin_user: admin_user} do
      user_to_impersonate = insert(:user)

      conn =
        user_to_impersonate
        |> guardian_login(conn, :access, perms: %{default: Guardian.Permissions.max}, imp: admin_user.id)
        |> delete(impersonate_session_path(conn, :delete))

      assert admin_user == Guardian.Plug.current_resource(conn)
      assert html_response(conn, 302) =~ "/admin/subscribers"
    end
  end

  defp insert_admin(_context) do
    {:ok, [admin_user: insert(:user, role: "customer_support")]}
  end
end
