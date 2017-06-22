defmodule ConciergeSite.CommuterRailSubscriptionControllerTest do
  use ConciergeSite.ConnCase

  describe "authorized" do
    setup :create_and_login_user

    test "GET /subscriptions/commuter_rail/new", %{conn: conn}  do
      conn = get(conn, "/subscriptions/commuter_rail/new")

      assert html_response(conn, 200) =~ "What type of trip do you take?"
    end

    test "GET /subscriptions/commuter_rail/new/info", %{conn: conn}  do
      conn = get(conn, "/subscriptions/commuter_rail/new/info")

      assert html_response(conn, 200) =~ "Info"
    end

    test "POST /subscriptions/commuter_rail/new/train", %{conn: conn}  do
      params = %{"subscription" => %{
        "departure_start" => "08:45 AM",
        "origin" => "place-north",
        "destination" => "Newburyport",
        "relevant_days" => "weekday",
        "trip_type" => "one_way",
      }}

      conn = post(conn, "/subscriptions/commuter_rail/new/train", params)

      assert html_response(conn, 200) =~ "Choose your trains"
    end

    test "POST /subscriptions/commuter_rail/new/preferences", %{conn: conn}  do
      params = %{"subscription" => %{
        "departure_start" => "08:45 AM",
        "origin" => "place-north",
        "destination" => "Newburyport",
        "relevant_days" => "weekday",
        "trip_type" => "one_way",
      }}

      conn = post(conn, "/subscriptions/commuter_rail/new/preferences", params)

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

  defp create_and_login_user(%{conn: conn}) do
    user = insert(:user)
    conn = guardian_login(user, conn)
    {:ok, [conn: conn]}
  end
end
