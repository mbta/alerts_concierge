defmodule ConciergeSite.V2.SessionControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Model.User, Repo}

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "GET /v2/login/new", %{conn: conn} do
    conn = get(conn, v2_session_path(conn, :new))
    assert html_response(conn, 200) =~ "Sign in"
  end

  test "POST /v2/login", %{conn: conn} do
    user = Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password})
    params = %{"user" => %{"email" => user.email,"password" => @password}}
    conn = post(conn, v2_session_path(conn, :create), params)
    assert html_response(conn, 302) =~ "<a href=\"/v2/account/new\">"
  end

  test "POST /v2/login rejected", %{conn: conn} do
    user = Repo.insert!(%User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password})
    params = %{"user" => %{"email" => user.email,"password" => "11111111111"}}
    conn = post(conn, v2_session_path(conn, :create), params)
    assert html_response(conn, 200) =~ "information was incorrect"
  end

  test "DELETE /v2/login", %{conn: conn} do
    user = insert(:user)

    conn = user
    |> guardian_login(conn)
    |> delete(v2_session_path(conn, :delete))

    assert redirected_to(conn, 302) =~ v2_session_path(conn, :new)
  end
end
