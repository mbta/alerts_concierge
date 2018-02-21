defmodule ConciergeSite.V2.AccountControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory

  test "GET /v2/account/new", %{conn: conn} do
    conn = get(conn, v2_account_path(conn, :new))
    assert html_response(conn, 200) =~ "new account"
  end

  test "POST /v2/account", %{conn: conn} do
    conn = post(conn, v2_account_path(conn, :create), %{})
    assert html_response(conn, 200) =~ "new account"
  end

  test "GET /v2/account/options", %{conn: conn} do
    user = insert(:user)

    conn = user
    |> guardian_login(conn)
    |> get(v2_account_path(conn, :options))

    assert html_response(conn, 200) =~ "account options"
  end
end
