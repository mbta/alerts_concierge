defmodule ConciergeSite.PageControllerTest do
  use ConciergeSite.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 302) =~ "my-subscriptions"
  end

  test "GET /account_disabled", %{conn: conn} do
    conn =
      :user
      |> insert()
      |> guardian_login(conn, :access, perms: %{default: [:disable_account]})
      |> get("/account_disabled")
    assert html_response(conn, 200) =~ "Account Disabled"
  end
end
