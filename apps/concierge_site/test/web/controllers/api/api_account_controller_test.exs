defmodule ConciergeSite.ApiAccountControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true

  setup do
    regular_user = insert(:user)
    admin_user = insert(:user, role: "admin")

    {:ok, regular_user: regular_user, admin_user: admin_user}
  end

  describe "DELETE /api/account/:user_id" do
    test "as an admin: deletes the user account", %{conn: conn, admin_user: admin_user} do
      user = insert(:user)

      conn =
        admin_user
        |> guardian_login(conn)
        |> delete(api_account_path(conn, :delete, user.id))

      assert json_response(conn, 200) == %{"result" => "success"}
    end

    test "not as an admin: doesn't allow you to delete the user account", %{
      conn: conn,
      regular_user: regular_user
    } do
      conn =
        regular_user
        |> guardian_login(conn)
        |> delete(api_account_path(conn, :delete, "3"))

      assert html_response(conn, 302)
    end

    test "not logged in: doesn't allow you to delete the user account", %{conn: conn} do
      conn = delete(conn, api_account_path(conn, :delete, "3"))

      assert html_response(conn, 302)
    end
  end
end
