defmodule ConciergeSite.V2.AccountControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory

  test "GET /v2/account/new", %{conn: conn} do
    conn = get(conn, v2_account_path(conn, :new))
    assert html_response(conn, 200) =~ "Create account"
  end

  test "POST /v2/account", %{conn: conn} do
    params = %{"user" => %{"password" => "Password1!", "email" => "test@test.com"}}
    conn = post(conn, v2_account_path(conn, :create), params)
    assert html_response(conn, 302) =~ "/v2/account/options"
  end

  test "POST /v2/account bad password", %{conn: conn} do
    params = %{"user" => %{"password" => "password", "email" => "test@test.com"}}
    conn = post(conn, v2_account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "Password must contain one number"
  end

  test "POST /v2/account bad email", %{conn: conn} do
    params = %{"user" => %{"password" => "password1!", "email" => "test"}}
    conn = post(conn, v2_account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "enter a valid email"
  end

  test "POST /v2/account empty values", %{conn: conn} do
    params = %{"user" => %{"password" => "", "email" => ""}}
    conn = post(conn, v2_account_path(conn, :create), params)
    assert html_response(conn, 200) =~ "be blank"
  end

  test "GET /v2/account/options", %{conn: conn} do
    user = insert(:user)

    conn = user
    |> guardian_login(conn)
    |> get(v2_account_path(conn, :options))

    assert html_response(conn, 200) =~ "account options"
  end
end
