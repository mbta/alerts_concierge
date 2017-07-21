defmodule ConciergeSite.PageControllerTest do
  use ConciergeSite.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 302) =~ "my-subscriptions"
  end
end
