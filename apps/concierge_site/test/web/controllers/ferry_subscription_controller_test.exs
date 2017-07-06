defmodule ConciergeSite.FerrySubscriptionControllerTest do
  use ConciergeSite.ConnCase

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  alias AlertProcessor.{Model.User, Repo}

  describe "authorized" do
    test "GET /subscriptions/ferry/new", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/ferry/new")

      assert html_response(conn, 200) =~ "What type of trip do you take?"
    end

    test "GET /subscriptions/ferry/new/info", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/ferry/new/info")

      assert html_response(conn, 200) =~ "Info"
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/ferry/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/ferry/new")
      assert html_response(conn, 302) =~ "/login"
    end

    test "GET /subscriptions/ferry/new/info", %{conn: conn} do
      conn = get(conn, "/subscriptions/ferry/new/info")
      assert html_response(conn, 302) =~ "/login"
    end
  end
end
