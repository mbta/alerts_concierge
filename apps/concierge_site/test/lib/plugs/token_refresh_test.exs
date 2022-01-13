defmodule ConciergeSite.Plugs.TokenRefreshTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  use Plug.Test

  alias ConciergeSite.Guardian
  alias ConciergeSite.Plugs.TokenRefresh

  test "it refreshes the token if it expires within fifteen minutes", %{conn: conn} do
    user = insert(:user)

    old_conn = Guardian.Plug.sign_in(conn, user, %{}, ttl: {14, :minutes})
    new_conn = TokenRefresh.call(old_conn, %{})

    old_claims = Guardian.Plug.current_claims(old_conn)
    new_claims = Guardian.Plug.current_claims(new_conn)
    assert old_claims["sub"] == new_claims["sub"]
    assert old_claims["pem"] == new_claims["pem"]
    assert old_claims["exp"] < new_claims["exp"]
  end

  test "it does nothing if the token expires more than fifteen minutes from now", %{conn: conn} do
    user = insert(:user)

    old_conn = Guardian.Plug.sign_in(conn, user, %{}, ttl: {16, :minutes})
    new_conn = TokenRefresh.call(old_conn, %{})

    assert old_conn == new_conn
  end

  test "it does nothing if there is no session", %{conn: conn} do
    new_conn = TokenRefresh.call(conn, %{})

    assert new_conn == conn
  end
end
