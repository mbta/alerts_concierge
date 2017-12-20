defmodule ConciergeSite.BikeStorageSubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{HoldingQueue, Model.Subscription, Model.InformedEntity, Repo}

  describe "authorized" do
    setup :login_user

    test "GET /subscriptions/bike_storage/new", %{conn: conn}  do
      conn = conn
      |> get("/subscriptions/bike_storage/new")

      assert html_response(conn, 200) =~ "Create a new alert subscription"
    end

    test "POST /subscriptions/bike_storage with valid params", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "relevant_days" => ["saturday"],
      }}

      conn = conn
      |> post("/subscriptions/bike_storage", params)

      subscriptions = Repo.all(Subscription)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert length(subscriptions) == 1
    end

    test "POST /subscriptions/bike_storage with invalid params", %{conn: conn} do
      params = %{"subscription" => %{
        "relevant_days" => [],
      }}

      conn = conn
      |> post("/subscriptions/bike_storage", params)

      expected_error = "Please correct the following errors to proceed: At least one station must be selected. At least one travel day must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 200) =~ "Create a new alert subscription"
      assert expected_error == error
    end

    test "POST /subscriptions/bike_storage with invalid params with stations selected", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "relevant_days" => [],
      }}

      conn = post(conn, "/subscriptions/bike_storage", params)

      expected_error = "Please correct the following errors to proceed: At least one travel day must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 200) =~ "Create a new alert subscription"
      assert html_response(conn, 200) =~ "North Quincy"
      assert html_response(conn, 200) =~ "Forest Hills"
      assert expected_error == error
    end

    test "GET /subscriptions/bike_storage/:id/edit", %{conn: conn, user: user} do
      bike_storage_subscription_entities =     [
        %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"},
        %InformedEntity{route_type: 4, facility_type: :elevator, stop: "place-nqncy"}
      ]

      sub = subscription_factory()
      |> Map.put(:informed_entities, bike_storage_subscription_entities)
      |> bike_storage_subscription()
      |> weekday_subscription()
      |> Map.merge(%{user: user})
      |> insert()

      use_cassette "bike_storage_update", clear_mock: true  do
        conn = get(conn, bike_storage_subscription_path(conn, :edit, sub.id))
        result = html_response(conn, 200)

        weekday_checked? = result =~ "<input checked=\"checked\" class=\"subscription-day-checkbox\" id=\"subscription_weekday\" name=\"subscription[relevant_days][]\" type=\"checkbox\" value=\"weekday\">"
        sunday_unchecked? = result =~ "<input class=\"subscription-day-checkbox\" id=\"subscription_sunday\" name=\"subscription[relevant_days][]\" type=\"checkbox\" value=\"sunday\">"

        assert result =~ "Subscribe to station bike storage alerts"

        assert weekday_checked?
        assert sunday_unchecked?
      end
    end

    test "PATCH /subscriptions/bike_storage/:id", %{conn: conn, user: user} do
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.enqueue(notification)
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, bike_storage_subscription_entities())
        |> bike_storage_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "relevant_days" => ["saturday"],
      }}

      use_cassette "bike_storage_update", clear_mock: true  do
        conn = patch(conn, "/subscriptions/bike_storage/#{subscription.id}", params)
        assert html_response(conn, 302) =~ "my-subscriptions"
        assert :error = HoldingQueue.pop()
      end
    end

    test "PATCH /subscriptions/bike_storage/:id with incomplete params", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, bike_storage_subscription_entities())
        |> bike_storage_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "relevant_days" => [],
      }}

      conn = patch(conn, "/subscriptions/bike_storage/#{subscription.id}", params)

      expected_error = "Please correct the following errors to proceed: At least one travel day must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 302) =~ "/subscriptions/bike_storage/#{subscription.id}/edit"
      assert expected_error == error
    end

    test "PATCH /subscriptions/bike_storage/:id with empty params", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, bike_storage_subscription_entities())
        |> bike_storage_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => [],
        "relevant_days" => [],
      }}

      conn = patch(conn, "/subscriptions/bike_storage/#{subscription.id}", params)

      expected_error = "Please correct the following errors to proceed: At least one station must be selected. At least one travel day must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 302) =~ "/subscriptions/bike_storage/#{subscription.id}/edit"
      assert expected_error == error
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/bike_storage/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/bike_storage/new")
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp login_user(%{conn: c}) do
    user = insert(:user)
    conn = guardian_login(user, c)
    {:ok, [conn: conn, user: user]}
  end
end
