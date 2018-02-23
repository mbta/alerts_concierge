defmodule ConciergeSite.V2.PageControllerTest do
  use ConciergeSite.ConnCase

  test "GET /v2", %{conn: conn} do
    conn = get(conn, v2_page_path(conn, :index))
    assert html_response(conn, 200) =~ "Welcome to T-Alerts!"
  end
end
