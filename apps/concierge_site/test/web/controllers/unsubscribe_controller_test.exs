defmodule ConciergeSite.UnsubscribeControllerTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.Auth.Token
  alias AlertProcessor.{Model.User, Repo}

  describe "valid token" do
    test "it puts user into vacation mode", %{conn: conn} do
      user = insert(:user)
      {:ok, token, _claims} = Token.issue(user, [:unsubscribe])
      conn = get(conn, unsubscribe_path(conn, :unsubscribe, token))
      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 200) =~ "You have been unsubscribed"
      assert updated_user.vacation_start != nil
      assert :eq = NaiveDateTime.compare(updated_user.vacation_end, ~N[9999-12-25 23:59:59])
    end
  end

  describe "invalid token" do
    test "does not allow user to unsubscribe without a token", %{conn: conn} do
      conn = get(conn, unsubscribe_path(conn, :unsubscribe, "not_a_token"))
      assert html_response(conn, 302) =~ "/"
    end

    test "requires valid permissions for route", %{conn: conn} do
      user = insert(:user)
      {:ok, token, _claims} = Token.issue(user, [:reset_password])
      conn = get(conn, unsubscribe_path(conn, :unsubscribe, token))
      assert html_response(conn, 302) =~ "/"
    end
  end
end
