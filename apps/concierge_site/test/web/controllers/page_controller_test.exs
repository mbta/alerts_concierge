defmodule ConciergeSite.PageControllerTest do
  use ConciergeSite.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 302) =~ "my-subscriptions"
  end

  test "GET /account_suspended", %{conn: conn} do
    conn = get conn, "/account_suspended"
    assert html_response(conn, 200) =~ "Account Suspended"
  end
end
