defmodule ConciergeSite.Admin.AdminUserControllerTest do
  use ConciergeSite.ConnCase

  describe "application_administration user" do
    test "GET /admin/admin_users", %{conn: conn} do
      conn =
        :user
        |> insert(role: "application_administration")
        |> guardian_login(conn, :token, %{
            default: Guardian.Permissions.max,
            admin: [:application_administration, :customer_support]
          })
        |> get(admin_admin_user_path(conn, :index))

      assert html_response(conn, 200) =~ "Admins"
    end
  end

  describe "customer_support user" do
    test "GET /admin/admin_users", %{conn: conn} do
      conn =
        :user
        |> insert(role: "customer_support")
        |> guardian_login(conn, :token, %{default: Guardian.Permissions.max, admin: [:customer_support]})
        |> get(admin_admin_user_path(conn, :index))

      assert html_response(conn, 403) =~ "Forbidden"
    end
  end

  describe "regular user" do
    test "GET /admin/admin_users", %{conn: conn} do
      conn =
        :user
        |> insert(role: "user")
        |> guardian_login(conn)
        |> get(admin_admin_user_path(conn, :index))

      assert html_response(conn, 403) =~ "Forbidden"
    end
  end

  describe "unauthenticated" do
    test "GET /admin/admin_users", %{conn: conn} do
      conn = get(conn, admin_admin_user_path(conn, :index))

      assert html_response(conn, 302) =~ "/login/new"
    end
  end

  describe "valid params" do
    test "admin user can create other admin users", %{conn: conn} do
      conn =
        :user
        |> insert(role: "application_administration")
        |> guardian_login(conn, :token, %{
            default: Guardian.Permissions.max,
            admin: [:application_administration, :customer_support]
          })

      admin_user_params =
              %{"user" => %{
                "email" => "admin@mbta.com",
                "password" => "password1",
                "password_confirmation" => "password1",
                "role" => "application_administration"
              }}

      conn = post(conn, "/admin/admin_users/", admin_user_params)
      assert html_response(conn, 302) =~ "/admin/admin_users"
    end
  end

  describe "invalid params" do
    test "admin user cannot create other admin users without valid params", %{conn: conn} do
      conn =
        :user
        |> insert(role: "application_administration")
        |> guardian_login(conn, :token, %{
            default: Guardian.Permissions.max,
            admin: [:application_administration, :customer_support]
          })

      invalid_admin_user_params =
              %{"user" => %{
                "email" => "admin@mbta.com",
                "password" => "password1",
                "password_confirmation" => "password1",
                "role" => nil
              }}

      conn = post(conn, "/admin/admin_users/", invalid_admin_user_params)
      response = html_response(conn, 200)

      assert response =~ "can&#39;t be blank"
    end
  end
end
