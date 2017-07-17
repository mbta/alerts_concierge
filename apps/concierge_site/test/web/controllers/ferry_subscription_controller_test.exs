defmodule ConciergeSite.FerrySubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  describe "authorized" do
    setup :create_and_login_user

    test "GET /subscriptions/ferry/new", %{conn: conn}  do
      conn = get(conn, "/subscriptions/ferry/new")

      assert html_response(conn, 200) =~ "What type of trip do you take?"
    end

    test "GET /subscriptions/ferry/new/info", %{conn: conn}  do
      conn = get(conn, "/subscriptions/ferry/new/info?trip_type=one_way")

      assert html_response(conn, 200) =~ "Info"
    end

    test "POST /subscriptions/ferry/new/ferry one_way", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "origin" => "Boat-Charlestown",
        "destination" => "Boat-Long",
        "relevant_days" => "weekday",
        "trip_type" => "one_way",
      }}

      use_cassette "ferry_one_way", clear_mock: true do
        conn = post(conn, "/subscriptions/ferry/new/ferry", params)

        assert html_response(conn, 200) =~ "Choose your ferries"
        assert html_response(conn, 200) =~ "10:15am from Charlestown Navy Yard, arrives at Long Wharf, Boston at 10:25am"
        refute html_response(conn, 200) =~ "from Long Wharf"
      end
    end

    test "POST /subscriptions/ferry/new/ferry round_trip", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "return_start" => "16:00:00",
        "origin" => "Boat-Long",
        "destination" => "Boat-Charlestown",
        "relevant_days" => "weekday",
        "trip_type" => "round_trip",
      }}

      use_cassette "ferry_round_trip", clear_mock: true do
        conn = post(conn, "/subscriptions/ferry/new/ferry", params)

        assert html_response(conn, 200) =~ "Choose your ferries"
        assert html_response(conn, 200) =~ "8:45am from Charlestown Navy Yard, arrives at Long Wharf, Boston at 8:55am"
        assert html_response(conn, 200) =~ "4:00pm from Long Wharf, Boston, arrives at Charlestown Navy Yard at 4:10pm"
      end
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

  defp create_and_login_user(%{conn: conn}) do
    user = insert(:user)
    conn = guardian_login(user, conn)
    {:ok, [conn: conn, user: user]}
  end
end
