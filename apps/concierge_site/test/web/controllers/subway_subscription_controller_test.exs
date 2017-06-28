defmodule ConciergeSite.SubwaySubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "authorized" do
    setup :insert_user

    test "GET /subscriptions/subway/new", %{conn: conn, user: user} do
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/subway/new")

      assert html_response(conn, 200) =~ "What type of trip do you take?"
    end

    test "GET /subscriptions/subway/new/info", %{conn: conn, user: user} do
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/subway/new/info")

      assert html_response(conn, 200) =~ "Enter your trip info"
    end

    test "POST /subscriptions/subway/new/preferences with a valid submission", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "origin" => "place-buest",
        "destination" => "place-buwst",
        "saturday" => "true",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "one_way",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/subway/new/preferences", params)

      assert html_response(conn, 200) =~ "Set your preferences for your trip:"
    end

    test "POST /subscriptions/subway/new/preferences with an invalid submission", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "origin" => "",
        "destination" => "",
        "saturday" => "false",
        "sunday" => "false",
        "weekday" => "false",
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

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
  end
end
