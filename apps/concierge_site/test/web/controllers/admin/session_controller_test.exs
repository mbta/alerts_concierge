defmodule ConciergeSite.Admin.SessionControllerTest do
  use ConciergeSite.ConnCase

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "GET /login", %{conn: conn} do
    conn = get(conn, admin_session_path(conn, :new))
    assert html_response(conn, 200) =~ "Admin"
  end

  test "POST /login with a customer suppport user", %{conn: conn} do
    user = insert(:user, role: "customer_support", encrypted_password: @encrypted_password)
    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, admin_session_path(conn, :create), params)
    assert html_response(conn, 302) =~ "/admin/subscribers"
  end

  test "POST /login with an application administration user", %{conn: conn} do
    user = insert(:user, role: "application_administration", encrypted_password: @encrypted_password)
    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, admin_session_path(conn, :create), params)

    assert html_response(conn, 302) =~ "/admin/subscribers"
  end

  test "POST /login with a deactivated_admin user", %{conn: conn} do
    user = insert(:user,
      role: "application_administration",
      encrypted_password: @encrypted_password,
      role: "deactivated_admin"
    )

    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, admin_session_path(conn, :create), params)

    assert html_response(conn, 200) =~ "Sorry, your account has been deactivated"
  end

  test "POST /login with a regular user", %{conn: conn} do
    user = insert(:user, role: "user", encrypted_password: @encrypted_password)
    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, admin_session_path(conn, :create), params)
    assert html_response(conn, 403) =~ "Your stop requires admin permission. This page is forbidden."
  end

  test "DELETE /login", %{conn: conn} do
    user = insert(:user, role: "customer_support")

    conn =
      user
      |> guardian_login(conn, :token, @customer_support_token_params)
      |> delete(admin_session_path(conn, :delete))

    assert html_response(conn, 302) =~ "admin/login/new"
  end
end
