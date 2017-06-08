defmodule ConciergeSite.SubscriptionControllerTest do
  use ConciergeSite.ConnCase

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  import AlertProcessor.Factory
  alias AlertProcessor.{Model.User, Repo}

  describe "authorized" do
    test "GET /my-subscriptions", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      sub =
        build(:subscription, user: user)
        |> weekday_subscription()
        |> subway_subscription()

      sub
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change
      |> Ecto.Changeset.put_assoc(:informed_entities, subway_subscription_entities())
      |> Repo.insert!



      conn = user
      |> guardian_login(conn)
      |> get("/my-subscriptions")

      assert html_response(conn, 200) =~ "My Subscriptions"
      assert html_response(conn, 200) =~ "Davis"
      assert html_response(conn, 200) =~ "Harvard"
    end

    test "GET /my-subscriptions redirects if no subscriptions", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/my-subscriptions")

      assert redirected_to(conn, 302) =~ subscription_path(conn, :new)
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
