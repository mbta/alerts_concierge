defmodule ConciergeSite.Web.SubscriptionControllerTest do
  use ConciergeSite.Web.ConnCase

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  alias AlertProcessor.{Model.User, Repo}

  describe "authorized" do
    test "GET /my-subscriptions", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/my-subscriptions")

      assert html_response(conn, 200) =~ "My Subscriptions"
    end
  end

  describe "unauthorized" do
    test "GET /my-subscriptions", %{conn: conn} do
      conn = get(conn, "/my-subscriptions")
      assert html_response(conn, 302) =~ "/login"
    end
  end
end
