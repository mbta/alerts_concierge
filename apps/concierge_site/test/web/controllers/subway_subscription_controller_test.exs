defmodule ConciergeSite.SubwaySubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{HoldingQueue, Model, Repo}
  alias Model.{InformedEntity, Subscription}

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

      assert html_response(conn, 200) =~ "Tell us about your trip"
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

      use_cassette "subway_preferences", custom: true, clear_mock: true, match_requests_on: [:query] do
        conn = user
        |> guardian_login(conn)
        |> post("/subscriptions/subway/new/preferences", params)

        assert html_response(conn, 200) =~ "Set your subscription preferences:"
      end
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

    test "POST /subscriptions/subway/new/preferences with missing origin", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "origin" => "",
        "destination" => "place-buest",
        "saturday" => "false",
        "sunday" => "false",
        "weekday" => "true",
        "trip_type" => "one_way",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/subway/new/preferences", params)

      assert html_response(conn, 200) =~ "Origin is invalid"
    end

    test "POST /subscriptions/subway/new/preferences with missing destination", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "origin" => "place-buest",
        "destination" => "",
        "saturday" => "false",
        "sunday" => "false",
        "weekday" => "true",
        "trip_type" => "one_way",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/subway/new/preferences", params)

      assert html_response(conn, 200) =~ "Destination is invalid"
    end

    test "POST /subscriptions/subway", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "alert_priority_type" => "high",
        "departure_end" => "09:15:00",
        "departure_start" => "08:45:00",
        "destination" => "place-qamnl",
        "origin" => "place-brntn",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true",
        "trip_type" => "one_way"
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/subway", params)

      subscriptions = Repo.all(Subscription)
      [ie | _] = InformedEntity |> Repo.all() |> Repo.preload(:subscription)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert length(subscriptions) == 1
      assert ie.subscription == List.first(subscriptions)
    end

    test "GET /subscriptions/subway/:id/edit", %{conn: conn, user: user} do
      factory =
        subscription_factory()
        |> subway_subscription()
        |> Map.merge(%{user: user})
      subscription = insert(factory)

      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/subway/#{subscription.id}/edit")

      assert html_response(conn, 200) =~ "Edit Subscription"
    end

    test "PATCH /subscriptions/subway/:id", %{conn: conn, user: user} do
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.enqueue(notification)
      subscription =
        subscription_factory()
        |> subway_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      params = %{"subscription" => %{
        "alert_priority_type" => "high",
        "departure_end" => "23:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("/subscriptions/subway/#{subscription.id}", params)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert :error = HoldingQueue.pop()
    end

    test "PATCH /subscriptions/subway/:id invalid timeframe", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> subway_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      params = %{"subscription" => %{
        "alert_priority_type" => "high",
        "departure_end" => "05:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("/subscriptions/subway/#{subscription.id}", params)

      assert html_response(conn, 200) =~ "Please correct the following errors to proceed: Start time on departure trip cannot be same as or later than end time. End of service day is 03:00AM."
    end

    test "PATCH /subscriptions/subway/:id invalid params", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> subway_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      params = %{"subscription" => %{
        "alert_priority_type" => "high",
        "departure_end" => "23:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "false",
        "sunday" => "false",
        "weekday" => "false"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("/subscriptions/subway/#{subscription.id}", params)

      assert html_response(conn, 200) =~ "Subscription could not be updated"
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/subway/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/subway/new")
      assert html_response(conn, 302) =~ "/login"
    end

    test "GET /subscriptions/subway/new/info", %{conn: conn} do
      conn = get(conn, "/subscriptions/subway/new/info")
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
  end
end
