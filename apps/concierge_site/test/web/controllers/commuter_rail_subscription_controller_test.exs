defmodule ConciergeSite.CommuterRailSubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  describe "authorized" do
    setup :create_and_login_user

    test "GET /subscriptions/commuter_rail/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/commuter_rail/new")

      assert html_response(conn, 200) =~ "What type of trip do you take?"
    end

    test "GET /subscriptions/commuter_rail/new/info", %{conn: conn} do
      conn = get(conn, "/subscriptions/commuter_rail/new/info")

      assert html_response(conn, 200) =~ "Info"
    end

    test "POST /subscriptions/commuter_rail/new/train one_way", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "origin" => "place-north",
        "destination" => "Newburyport",
        "relevant_days" => "weekday",
        "trip_type" => "one_way",
      }}

      use_cassette "commuter_rail_train_one_way", custom: true, clear_mock: true, match_requests_on: [:query] do
        conn = post(conn, "/subscriptions/commuter_rail/new/train", params)

        assert html_response(conn, 200) =~ "Choose your trains"
        assert html_response(conn, 200) =~ "Departs North Station"
        refute html_response(conn, 200) =~ "Departs Newburyport"
      end
    end

    test "POST /subscriptions/commuter_rail/new/train round_trip", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "return_start" => "16:00:00",
        "origin" => "place-north",
        "destination" => "Newburyport",
        "relevant_days" => "weekday",
        "trip_type" => "round_trip",
      }}

      use_cassette "commuter_rail_train_round_trip", custom: true, clear_mock: true, match_requests_on: [:query] do
        conn = post(conn, "/subscriptions/commuter_rail/new/train", params)

        assert html_response(conn, 200) =~ "Choose your trains"
        assert html_response(conn, 200) =~ "Departs North Station"
        assert html_response(conn, 200) =~ "Departs Newburyport"
      end
    end

    test "POST /subscriptions/commuter_rail/new/preferences", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "origin" => "place-north",
        "destination" => "Newburyport",
        "trips" => ["123"],
        "relevant_days" => "weekday",
        "trip_type" => "one_way",
      }}

      conn = post(conn, "/subscriptions/commuter_rail/new/preferences", params)

      assert html_response(conn, 200) =~ "Set your preferences for your trip:"
    end

    test "POST /subscriptions/commuter_rail/new/preferences with invalid params for one way", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "origin" => "place-north",
        "destination" => "Newburyport",
        "trips" => [],
        "relevant_days" => "weekday",
        "trip_type" => "one_way",
      }}

      use_cassette "commuter_rail_train_one_way", clear_mock: true do
        conn = post(conn, "/subscriptions/commuter_rail/new/preferences", params)

        assert html_response(conn, 200) =~ "Choose your trains"
        assert html_response(conn, 200) =~ "lease select at least one trip."
      end
    end

    test "POST /subscriptions/commuter_rail/new/preferences with invalid params for round trip", %{conn: conn} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "return_start" => "17:45:00",
        "origin" => "place-north",
        "destination" => "Newburyport",
        "trips" => [],
        "return_trips" => [],
        "relevant_days" => "weekday",
        "trip_type" => "round_trip",
      }}

      use_cassette "commuter_rail_train_round_trip", clear_mock: true do
        conn = post(conn, "/subscriptions/commuter_rail/new/preferences", params)

        assert html_response(conn, 200) =~ "Choose your trains"
        assert html_response(conn, 200) =~ "Please select at least one trip."
        assert html_response(conn, 200) =~ "Please select at least one return trip."
      end
    end

    test "POST /subscriptions/commuter_rail", %{conn: conn} do
      params = %{"subscription" => %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-north",
        "trips" => ["1312", "1314"],
        "relevant_days" => "saturday",
        "departure_start" => "12:00:00",
        "alert_priority_type" => "low",
        "trip_type" => "one_way"
      }}

      use_cassette "commuter_rail_create", clear_mock: true do
        conn = post(conn, "/subscriptions/commuter_rail", params)

        subscriptions = Repo.all(Subscription)
        [ie | _] = InformedEntity |> Repo.all() |> Repo.preload(:subscription)

        assert html_response(conn, 302) =~ "my-subscriptions"
        assert length(subscriptions) == 1
        assert ie.subscription == List.first(subscriptions)
      end
    end

    test "GET /subscriptions/commuter_rail/:id/edit", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, commuter_rail_subscription_entities())
        |> commuter_rail_subscription()
        |> Map.merge(%{user: user, relevant_days: [:weekday]})
        |> insert()

      use_cassette "commuter_rail_edit", clear_mock: true do
        conn = get(conn, "/subscriptions/commuter_rail/#{subscription.id}/edit")

        assert html_response(conn, 200) =~ "Edit Subscription"
      end
    end

    test "PATCH /subscriptions/commuter_rail/:id", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, commuter_rail_subscription_entities())
        |> commuter_rail_subscription()
        |> Map.merge(%{user: user, relevant_days: [:weekday]})
        |> insert()

      params = %{"subscription" => %{
        "alert_priority_type" => "high",
        "trips" => ["341"]
      }}

      use_cassette "commuter_rail_update", clear_mock: true  do
        conn = patch(conn, "/subscriptions/commuter_rail/#{subscription.id}", params)

        assert html_response(conn, 302) =~ "my-subscriptions"
      end
    end

    test "PATCH /subscriptions/commuter_rail/:id displays error if trip not selected", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, commuter_rail_subscription_entities())
        |> commuter_rail_subscription()
        |> Map.merge(%{user: user, relevant_days: [:weekday]})
        |> insert()

      params = %{"subscription" => %{
        "alert_priority_type" => "high",
        "trips" => []
      }}

      use_cassette "commuter_rail_update_invalid", clear_mock: true do
        conn = patch(conn, "/subscriptions/commuter_rail/#{subscription.id}", params)

        assert html_response(conn, 200) =~ "Edit Subscription"
        assert html_response(conn, 200) =~ "Please select at least one trip"
      end
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
    {:ok, [conn: conn, user: user]}
  end
end
