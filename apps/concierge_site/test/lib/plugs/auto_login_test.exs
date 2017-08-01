defmodule ConciergeSite.Plugs.AutoLoginTest do
  use ConciergeSite.ConnCase
  use Plug.Test

  alias ConciergeSite.{Auth.Token, Plugs.AutoLogin}

  test "it sets token in session if valid token", %{conn: conn} do
    user = insert(:user)
    {:ok, token, _} = Token.issue(user, [:disable_account])
    conn = init_test_session(%{conn | params: %{"token" => token}}, %{})
    new_conn = AutoLogin.call(conn, %{})
    refute new_conn == conn
    assert get_session(new_conn, "guardian_default") == token
  end

  test "it does nothing if token is invalid", %{conn: conn} do
    conn = init_test_session(%{conn | params: %{"token" => "not-a-token"}}, %{})
    new_conn = AutoLogin.call(conn, %{})
    assert new_conn == conn
  end

  test "it does nothing if token is not present", %{conn: conn} do
    conn = init_test_session(%{conn | params: %{}}, %{})
    new_conn = AutoLogin.call(conn, %{})
    assert new_conn == conn
  end
end
