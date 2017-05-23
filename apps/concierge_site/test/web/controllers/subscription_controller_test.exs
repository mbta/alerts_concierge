defmodule ConciergeSite.SubscriptionControllerTest do
  use ConciergeSite.ConnCase

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

    test "GET /subscriptions/new", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/new")

      assert html_response(conn, 200) =~ "Create New Subscription"
    end
  end

  describe "unauthorized" do
    test "GET /my-subscriptions", %{conn: conn} do
      conn = get(conn, "/my-subscriptions")
      assert html_response(conn, 302) =~ "/login"
    end

    test "GET /subscriptions/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/new")
      assert html_response(conn, 302) =~ "/login"
    end
  end
end
