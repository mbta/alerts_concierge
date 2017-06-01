defmodule ConciergeSite.SubwaySubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  alias AlertProcessor.{Model.User, Repo}

  describe "authorized" do
    test "GET /subscriptions/subway/new", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/subway/new")

      assert html_response(conn, 200) =~ "What type of trip do you take?"
    end

    test "GET /subscriptions/subway/new/info", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/subway/new/info")

      assert html_response(conn, 200) =~ "Enter your trip info"
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/subway/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/subway/new")
      assert html_response(conn, 302) =~ "/login"
    end

    test "GET /subscriptions/subway/new/info", %{conn: conn} do
      use_cassette "service_info", custom: true, clear_mock: true do
        conn = get(conn, "/subscriptions/subway/new/info")
        assert html_response(conn, 302) =~ "/login"
      end
    end
  end
end
