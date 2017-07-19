defmodule ConciergeSite.FerrySubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{InformedEntity, Subscription}

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

      conn = post(conn, "/subscriptions/ferry/new/ferry", params)

      assert html_response(conn, 200) =~ "Choose your ferries"
      assert html_response(conn, 200) =~ "10:15am from Charlestown Navy Yard, arrives at Long Wharf, Boston at 10:25am"
      refute html_response(conn, 200) =~ "from Long Wharf"
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

      conn = post(conn, "/subscriptions/ferry/new/ferry", params)

      assert html_response(conn, 200) =~ "Choose your ferries"
      assert html_response(conn, 200) =~ "8:45am from Charlestown Navy Yard, arrives at Long Wharf, Boston at 8:55am"
      assert html_response(conn, 200) =~ "4:00pm from Long Wharf, Boston, arrives at Charlestown Navy Yard at 4:10pm"
    end

    test "POST /subscriptions/ferry/new/preferences", %{conn: conn} do
      params = %{"subscription" => %{
        "origin" => "Boat-Long",
        "destination" => "Boat-Hingham",
        "trips" => ["Boat-F1-Boat-Hingham-10:00:00-weekday-1", "Boat-F1-Boat-Hingham-12:00:00-weekday-1"],
        "relevant_days" => "weekday",
        "departure_start" => "09:00:00",
        "alert_priority_type" => "low",
        "trip_type" => "one_way"
      }}

      conn = post(conn, "/subscriptions/ferry/new/preferences", params)

      assert html_response(conn, 200) =~ "Set your preferences for your trip:"
      assert html_response(conn, 200) =~ "2 ferries"
    end

    test "POST /subscriptions/ferry/new/preferences with invalid params for one way", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "origin" => "Boat-Charlestown",
        "destination" => "Boat-Long",
        "trips" => [],
        "relevant_days" => "weekday",
        "trip_type" => "one_way",
      }}

      conn = post(conn, "/subscriptions/ferry/new/preferences", params)

      assert html_response(conn, 200) =~ "Choose your ferries"
      assert html_response(conn, 200) =~ "lease select at least one trip."
    end

    test "POST /subscriptions/ferry/new/preferences with invalid params for round trip", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "return_start" => "17:45:00",
        "origin" => "Boat-Long",
        "destination" => "Boat-Charlestown",
        "trips" => [],
        "return_trips" => [],
        "relevant_days" => "weekday",
        "trip_type" => "round_trip",
      }}

      conn = post(conn, "/subscriptions/ferry/new/preferences", params)

      assert html_response(conn, 200) =~ "Choose your ferries"
      assert html_response(conn, 200) =~ "Please select at least one trip."
      assert html_response(conn, 200) =~ "Please select at least one return trip."
    end

    test "POST /subscriptions/ferry", %{conn: conn} do
      params = %{"subscription" => %{
        "origin" => "Boat-Long",
        "destination" => "Boat-Hingham",
        "trips" => ["Boat-F1-Boat-Hingham-10:00:00-weekday-1", "Boat-F1-Boat-Hingham-12:00:00-weekday-1"],
        "relevant_days" => "weekday",
        "departure_start" => "09:00:00",
        "alert_priority_type" => "low",
        "trip_type" => "one_way"
      }}

      use_cassette "ferry_create", clear_mock: true do
        conn = post(conn, "/subscriptions/ferry", params)

        subscriptions = Repo.all(Subscription)
        [ie | _] = InformedEntity |> Repo.all() |> Repo.preload(:subscription)

        assert html_response(conn, 302) =~ "my-subscriptions"
        assert length(subscriptions) == 1
        assert ie.subscription == List.first(subscriptions)
      end
    end

    test "GET /subscriptions/ferry/:id/edit", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, ferry_subscription_entities())
        |> ferry_subscription()
        |> Map.merge(%{user: user, relevant_days: [:weekday]})
        |> insert()

      conn = get(conn, "/subscriptions/ferry/#{subscription.id}/edit")

      assert html_response(conn, 200) =~ "Edit Subscription"
    end

    test "PATCH /subscriptions/ferry/:id", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, ferry_subscription_entities())
        |> ferry_subscription()
        |> Map.merge(%{user: user, relevant_days: [:weekday]})
        |> insert()

      params = %{"subscription" => %{
        "alert_priority_type" => "high",
        "trips" => ["Boat-F4-Boat-Charlestown-11:15:00-weekday-1"]
      }}

      conn = patch(conn, "/subscriptions/ferry/#{subscription.id}", params)

      assert html_response(conn, 302) =~ "my-subscriptions"
    end

    test "PATCH /subscriptions/ferry/:id displays error if trip not selected", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, ferry_subscription_entities())
        |> ferry_subscription()
        |> Map.merge(%{user: user, relevant_days: [:weekday]})
        |> insert()

      params = %{"subscription" => %{
        "alert_priority_type" => "high",
        "trips" => []
      }}

      conn = patch(conn, "/subscriptions/ferry/#{subscription.id}", params)

      assert html_response(conn, 200) =~ "Edit Subscription"
      assert html_response(conn, 200) =~ "Please select at least one trip"
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
