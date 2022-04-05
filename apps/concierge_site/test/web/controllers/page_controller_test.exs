defmodule ConciergeSite.PageControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, page_path(conn, :landing))

    assert html_response(conn, 200) =~ "Service alerts, when"
  end

  test "GET /deleted", %{conn: conn} do
    conn = get(conn, page_path(conn, :account_deleted))

    assert html_response(conn, 200) =~ "Your account has been deleted"
  end
end
