defmodule ConciergeSite.V2.PageControllerTest do
  use ConciergeSite.ConnCase

  test "GET /trip_type", %{conn: conn} do
    conn = get(conn, v2_page_path(conn, :trip_type))

    assert html_response(conn, 200) =~ "What kind of alerts would you like to set up?"
  end

  test "GET /v2/deleted", %{conn: conn} do
    conn = get(conn, v2_page_path(conn, :account_deleted))

    assert html_response(conn, 200) =~ "Your account has been deleted"
  end
end
