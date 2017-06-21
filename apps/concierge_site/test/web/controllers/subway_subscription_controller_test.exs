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

    test "POST /subscriptions/subway/new/preferences with a valid submission", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})

      params = %{"subscription" => %{
        "departure_start" => "08:45 AM",
        "departure_end" => "09:15 AM",
        "origin" => "place-buest",
        "destination" => "place-buwst",
        "saturday" => "true",
        "sunday" => "false",
        "weekdays" => "false",
        "trip_type" => "one_way",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/subway/new/preferences", params)

      assert html_response(conn, 200) =~ "Set your preferences for your trip:"
    end

    test "POST /subscriptions/subway/new/preferences with an invalid submission", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})

      params = %{"subscription" => %{
        "departure_start" => "08:45 AM",
        "departure_end" => "09:15 AM",
        "origin" => "",
        "destination" => "",
        "saturday" => "false",
        "sunday" => "false",
        "weekdays" => "false",
        "trip_type" => "one_way",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/subway/new/preferences", params)

      assert html_response(conn, 200) =~ "Please correct the following errors to proceed"
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
