defmodule ConciergeSite.Plugs.TokenRefreshTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  use Plug.Test

  alias ConciergeSite.{Plugs.TokenLogin, Plugs.TokenRefresh}

  defp issue_token(user, ttl_minutes \\ 60) do
    Guardian.encode_and_sign(user, :access,
      perms: %{default: Guardian.Permissions.max()},
      ttl: {ttl_minutes, :minutes}
    )
  end

  test "it refreshes the token if it expires within fifteen minutes", %{conn: conn} do
    user = insert(:user)
    {:ok, token, _} = issue_token(user, 14)

    conn =
      %{conn | params: %{"token" => token}}
      |> init_test_session(%{})
      |> TokenLogin.call(%{})

    refreshed_conn = TokenRefresh.call(conn, %{})
    new_token = get_session(conn, "guardian_default")
    refute refreshed_conn == conn
    refute get_session(refreshed_conn, "guardian_default") == new_token
    {:ok, old_claims} = Guardian.decode_and_verify(token)
    {:ok, new_claims} = Guardian.decode_and_verify(new_token)
    assert Map.take(old_claims, ["pem", "sub"]) == Map.take(new_claims, ["pem", "sub"])
  end

  test "it does nothing if the token expires more than fifteen minutes from now", %{conn: conn} do
    user = insert(:user)
    {:ok, token, _} = issue_token(user, 16)

    conn =
      %{conn | params: %{"token" => token}}
      |> init_test_session(%{})
      |> TokenLogin.call(%{})

    refreshed_conn = TokenRefresh.call(conn, %{})
    assert refreshed_conn == conn

    assert get_session(refreshed_conn, "guardian_default") ==
             get_session(conn, "guardian_default")

    assert {:ok, _claims} = Guardian.decode_and_verify(token)
  end

  test "it does nothing if there is no session", %{conn: conn} do
    user = insert(:user)
    {:ok, token, _} = issue_token(user)
    conn = init_test_session(%{conn | params: %{"token" => token}}, %{})
    new_conn = TokenRefresh.call(conn, %{})
    assert new_conn == conn
  end
end
