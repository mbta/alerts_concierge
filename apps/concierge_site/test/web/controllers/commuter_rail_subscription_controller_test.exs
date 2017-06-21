defmodule ConciergeSite.CommuterRailSubscriptionControllerTest do
  use ConciergeSite.ConnCase

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  alias AlertProcessor.{Model.User, Repo}

  describe "authorized" do
    test "GET /subscriptions/commuter_rail/new", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/commuter_rail/new")

      assert html_response(conn, 200) =~ "What type of trip do you take?"
    end

    test "GET /subscriptions/commuter_rail/new/info", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/commuter_rail/new/info")

      assert html_response(conn, 200) =~ "Info"
    end

    test "POST /subscriptions/commuter_rail/new/preferences", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
       params = %{"subscription" => %{
        "departure_start" => "08:45 AM",
        "origin" => "place-north",
        "destination" => "Newburyport",
        "relevant_days" => "weekday",
        "trip_type" => "one_way",
      }}
       conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/commuter_rail/new/preferences", params)

       assert html_response(conn, 200) =~ "Set your preferences for your trip:"
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/commuter_rail/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/commuter_rail/new")
      assert html_response(conn, 302) =~ "/login"
    end

    test "GET /subscriptions/commuter_rail/new/info", %{conn: conn} do
      conn = get(conn, "/subscriptions/commuter_rail/new/info")
      assert html_response(conn, 302) =~ "/login"
    end
  end
end
