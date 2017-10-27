defmodule ConciergeSite.BusSubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{HoldingQueue, Model, Repo}
  alias Model.{InformedEntity, Subscription}

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  alias AlertProcessor.{Model.User, Repo}

  describe "authorized" do
    setup :insert_user

    test "GET /subscriptions/bus/new", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/bus/new")

      assert html_response(conn, 200) =~ "What type of trip do you take?"
    end

    test "GET /subscriptions/bus/new/info", %{conn: conn}  do
      user = Repo.insert!(%User{email: "test@email.com",
                                role: "user",
                                encrypted_password: @encrypted_password})
      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/bus/new/info")

      assert html_response(conn, 200) =~ "Info"
    end

    test "POST /subscriptions/bus/new/preferences with a valid submission", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "routes" => ["741 - 1"],
        "saturday" => "true",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "one_way",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/bus/new/preferences", params)

      assert html_response(conn, 200) =~ "Set your subscription preferences:"
      assert html_response(conn, 200) =~ "Route Silver Line SL1 inbound, Saturday  8:45 AM -  9:15 AM"
    end

    test "POST /subscriptions/bus/new/preferences with an invalid submission", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "routes" => [],
        "saturday" => "false",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "one_way",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/bus/new/preferences", params)

      assert html_response(conn, 200) =~ "Please correct the following errors to proceed: At least one travel day option must be selected. Route is invalid."
    end

    test "POST /subscriptions/bus/new/preferences displays summary of a one-way trip", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "routes" => ["741 - 1"],
        "saturday" => "true",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "one_way",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/bus/new/preferences", params)

      response = html_response(conn, 200)
      assert response =~ "Route Silver Line SL1 inbound, Saturday  8:45 AM -  9:15 AM"
    end

    test "POST /subscriptions/bus/new/preferences displays summary of a round trip", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "return_start" => "16:45:00",
        "return_end" => "17:15:00",
        "routes" => ["741 - 1"],
        "saturday" => "true",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "round_trip",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/bus/new/preferences", params)

      response = html_response(conn, 200)
      assert response =~ "Route Silver Line SL1 inbound, Saturday  8:45 AM -  9:15 AM"
      assert response =~ "Route Silver Line SL1 outbound, Saturday  4:45 PM -  5:15 PM"
    end

    test "POST /subscriptions/bus/new/preferences displays summary of a round trip multi route", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "return_start" => "16:45:00",
        "return_end" => "17:15:00",
        "routes" => ["741 - 1", "87 - 1"],
        "saturday" => "true",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "round_trip",
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/bus/new/preferences", params)

      response = html_response(conn, 200)
      assert response =~ "2 Bus Routes, Saturday  8:45 AM -  9:15 AM"
      assert response =~ "Silver Line SL1 outbound"
      assert response =~ "87 outbound"
    end

    test "POST /subscriptions/bus creates subscriptions", %{conn: conn, user: user} do
      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "return_start" => "16:45:00",
        "return_end" => "17:15:00",
        "routes" => "741 - 1",
        "saturday" => "true",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "round_trip",
        "alert_priority_type" => "low"
      }}

      conn = user
      |> guardian_login(conn)
      |> post("/subscriptions/bus", params)

      subscriptions = Repo.all(Subscription)
      [ie | _] = InformedEntity |> Repo.all() |> Repo.preload(:subscription)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert length(subscriptions) == 2
      assert ie.subscription == List.first(subscriptions)
    end

    test "GET /subscriptions/bus/:id/edit", %{conn: conn, user: user} do
      factory =
        subscription_factory()
        |> bus_subscription()
        |> Map.put(:informed_entities, bus_subscription_entities())
        |> Map.merge(%{user: user})
      subscription = insert(factory)

      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/bus/#{subscription.id}/edit")

      assert html_response(conn, 200) =~ "Edit Subscription"
      assert html_response(conn, 200) =~ "57A outbound"
    end

    test "GET /subscriptions/bus/:id/edit multi route", %{conn: conn, user: user} do
      factory =
        subscription_factory()
        |> bus_subscription()
        |> Map.put(:informed_entities, Enum.uniq(bus_subscription_entities() ++ bus_subscription_entities("87")))
        |> Map.merge(%{user: user})
      subscription = insert(factory)

      conn = user
      |> guardian_login(conn)
      |> get("/subscriptions/bus/#{subscription.id}/edit")

      assert html_response(conn, 200) =~ "Edit Subscription"
      assert html_response(conn, 200) =~ "2 Bus Routes"
      assert html_response(conn, 200) =~ "57A outbound"
      assert html_response(conn, 200) =~ "87 outbound"
    end

    test "PATCH /subscriptions/bus/:id", %{conn: conn, user: user} do
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.enqueue(notification)
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "return_start" => "16:45:00",
        "return_end" => "17:15:00",
        "routes" => "741 - 1",
        "saturday" => "true",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "round_trip",
        "alert_priority_type" => "low"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("/subscriptions/bus/#{subscription.id}", params)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert :error = HoldingQueue.pop()
    end

    test "PATCH /subscriptions/bus/:id invalid timeframe", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> weekday_subscription()
        |> Map.put(:informed_entities, bus_subscription_entities())
        |> Map.merge(%{user_id: user.id})
        |> insert()

      params = %{"subscription" => %{
        "departure_start" => "22:45:00",
        "departure_end" => "09:15:00",
        "return_start" => "16:45:00",
        "return_end" => "17:15:00",
        "routes" => "741 - 1",
        "saturday" => "true",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "round_trip",
        "alert_priority_type" => "low"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("/subscriptions/bus/#{subscription.id}", params)

      assert html_response(conn, 200) =~ "Please correct the following errors to proceed: Start time on departure trip cannot be same as or later than end time. End of service day is 03:00AM."
    end

    test "PATCH /subscriptions/bus/:id invalid params", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> weekday_subscription()
        |> Map.put(:informed_entities, bus_subscription_entities())
        |> Map.merge(%{user_id: user.id})
        |> insert()

      params = %{"subscription" => %{
        "departure_start" => "08:45:00",
        "departure_end" => "09:15:00",
        "return_start" => "16:45:00",
        "return_end" => "17:15:00",
        "routes" => "741 - 1",
        "saturday" => "false",
        "sunday" => "false",
        "weekday" => "false",
        "trip_type" => "round_trip",
        "alert_priority_type" => "low"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("/subscriptions/bus/#{subscription.id}", params)

      assert html_response(conn, 200) =~ "Subscription could not be updated"
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/bus/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/bus/new")
      assert html_response(conn, 302) =~ "/login"
    end

    test "GET /subscriptions/subway/new/info", %{conn: conn} do
      conn = get(conn, "/subscriptions/bus/new/info")
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
  end
end
