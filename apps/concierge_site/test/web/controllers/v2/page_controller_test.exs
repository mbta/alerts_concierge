defmodule ConciergeSite.V2.PageControllerTest do
  use ConciergeSite.ConnCase

  test "GET /v2", %{conn: conn} do
    conn = get(conn, v2_page_path(conn, :index))
    assert html_response(conn, 200) =~ "Welcome to T-Alerts!"
  end

  test "GET /v2/trip_type", %{conn: conn} do
    conn = get(conn, v2_page_path(conn, :trip_type))

    assert html_response(conn, 200) =~ "What kind of alerts would you like to setup?"
  end
end
