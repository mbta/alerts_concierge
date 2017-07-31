defmodule ConciergeSite.Admin.SessionControllerTest do
  use ConciergeSite.ConnCase

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "GET /login", %{conn: conn} do
    conn = get(conn, admin_session_path(conn, :new))
    assert html_response(conn, 200) =~ "Admin"
  end

  test "POST /login with a junior admin", %{conn: conn} do
    user = insert(:user, role: "junior_admin", encrypted_password: @encrypted_password)
    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, admin_session_path(conn, :create), params)
    assert html_response(conn, 302) =~ "/admin/subscribers"
  end

  test "POST /login with a super admin", %{conn: conn} do
    user = insert(:user, role: "super_admin", encrypted_password: @encrypted_password)
    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, admin_session_path(conn, :create), params)

    assert html_response(conn, 302) =~ "/admin/subscribers"
  end

  test "POST /login with a regular user", %{conn: conn} do
    user = insert(:user, role: "user", encrypted_password: @encrypted_password)
    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, admin_session_path(conn, :create), params)
    assert html_response(conn, 200) =~ "Sorry, you are not authorized to log in."
  end
end
