defmodule ConciergeSite.SessionControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory
  alias Hammer

  describe "GET /login/new" do
    test "redirects to Keycloak login page", %{conn: conn} do
      conn = get(conn, session_path(conn, :new))

      assert redirected_to(conn, 302) == "/auth/keycloak"
    end
  end

  test "DELETE /login", %{conn: conn} do
    user = insert(:user)

    conn =
      user
      |> guardian_login(conn)
      |> delete(session_path(conn, :delete))

    assert redirected_to(conn, 302) =~ ~r/post_logout_redirect_uri=.+/
  end

  test "unauthenticated/2", %{conn: conn} do
    # trip index path requires authentication so it is handled by
    # `unauthenticated/2` if user has not logged in
    conn = get(conn, trip_path(conn, :index))
    assert redirected_to(conn, 302) =~ session_path(conn, :new)
  end
end
