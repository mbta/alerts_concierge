defmodule ConciergeSite.V2.PageControllerTest do
  use ConciergeSite.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, v2_page_path(conn, :landing))

    assert html_response(conn, 200) =~ "Try the new"
  end

  test "GET /v2/deleted", %{conn: conn} do
    conn = get(conn, v2_page_path(conn, :account_deleted))

    assert html_response(conn, 200) =~ "Your account has been deleted"
  end
end
