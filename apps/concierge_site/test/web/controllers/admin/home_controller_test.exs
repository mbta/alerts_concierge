defmodule ConciergeSite.Admin.HomeControllerTest do
  use ConciergeSite.ConnCase, async: true

  describe "index/2" do
    test "is accessible to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "admin"), conn)

      resp = conn |> get(admin_home_path(conn, :index)) |> html_response(200)

      assert resp =~ "Administration"
    end

    test "is not accessible to non-admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = conn |> get(admin_home_path(conn, :index))

      assert redirected_to(conn) =~ session_path(conn, :new)
    end
  end
end
