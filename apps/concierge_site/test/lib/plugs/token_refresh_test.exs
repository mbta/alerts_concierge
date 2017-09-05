defmodule ConciergeSite.Plugs.TokenRefreshTest do
  use ConciergeSite.ConnCase
  use Plug.Test

  alias ConciergeSite.{Auth.Token, Plugs.TokenLogin, Plugs.TokenRefresh}

  test "it refreshes the token in session", %{conn: conn} do
    user = insert(:user)
    {:ok, token, _} = Token.issue(user)
    conn = init_test_session(%{conn | params: %{"token" => token}}, %{})
    conn =
      conn
      |> TokenLogin.call(%{})
    refreshed_conn = TokenRefresh.call(conn, %{})
    refute refreshed_conn == conn
    refute get_session(refreshed_conn, "guardian_default") == get_session(conn, "guardian_default")
  end

  test "it does not immediately expire the old token", %{conn: conn} do
    user = insert(:user)
    {:ok, token, _} = Token.issue(user)
    conn = init_test_session(%{conn | params: %{"token" => token}}, %{})
    conn = TokenLogin.call(conn, %{})
    TokenRefresh.call(conn, %{})

    assert {:ok, _claims} = Guardian.decode_and_verify(token)
  end

  test "it does nothing if there is no session", %{conn: conn} do
    user = insert(:user)
    {:ok, token, _} = Token.issue(user)
    conn = init_test_session(%{conn | params: %{"token" => token}}, %{})
    new_conn = TokenRefresh.call(conn, %{})
    assert new_conn == conn
  end
end
