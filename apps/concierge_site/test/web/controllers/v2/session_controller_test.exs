defmodule ConciergeSite.V2.SessionControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory

  test "GET /v2/login/new", %{conn: conn} do
    conn = get(conn, v2_session_path(conn, :new))
    assert html_response(conn, 200) =~ "new session"
  end

  test "POST /v2/login", %{conn: conn} do
    conn = post(conn, v2_session_path(conn, :create), %{})
    assert html_response(conn, 200) =~ "new session"
  end

  test "DELETE /v2/login", %{conn: conn} do
    user = insert(:user)

    conn = user
    |> guardian_login(conn)
    |> delete(v2_session_path(conn, :delete))

    assert redirected_to(conn, 302) =~ v2_session_path(conn, :new)
  end
end
