defmodule ConciergeSite.ParkingSubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{HoldingQueue, Model.Subscription, Model.InformedEntity, Repo}

  describe "authorized" do
    setup :login_user

    test "GET /subscriptions/parking/new", %{conn: conn}  do
      conn = conn
      |> get("/subscriptions/parking/new")

      assert html_response(conn, 200) =~ "Create a new parking alert"
    end

    test "POST /subscriptions/parking with valid params", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "relevant_days" => ["saturday"],
      }}

      conn = conn
      |> post("/subscriptions/parking", params)

      subscriptions = Repo.all(Subscription)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert length(subscriptions) == 1
    end

    test "POST /subscriptions/parking with invalid params", %{conn: conn} do
      params = %{"subscription" => %{
        "relevant_days" => [],
      }}

      conn = conn
      |> post("/subscriptions/parking", params)

      expected_error = "Please correct the following errors to proceed: At least one station must be selected. At least one travel day must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 200) =~ "Create a new parking alert"
      assert expected_error == error
    end

    test "POST /subscriptions/parking with invalid params with stations selected", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "relevant_days" => [],
      }}

      conn = post(conn, "/subscriptions/parking", params)

      expected_error = "Please correct the following errors to proceed: At least one travel day must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 200) =~ "Create a new parking alert"
      assert html_response(conn, 200) =~ "North Quincy"
      assert html_response(conn, 200) =~ "Forest Hills"
      assert expected_error == error
    end

    test "GET /subscriptions/parking/:id/edit", %{conn: conn, user: user} do
      parking_subscription_entities =     [
        %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"},
        %InformedEntity{route_type: 4, facility_type: :elevator, stop: "place-nqncy"}
      ]

      sub = subscription_factory()
      |> Map.put(:informed_entities, parking_subscription_entities)
      |> parking_subscription()
      |> weekday_subscription()
      |> Map.merge(%{user: user})
      |> insert()

      use_cassette "parking_update", clear_mock: true  do
        conn = get(conn, parking_subscription_path(conn, :edit, sub.id))
        result = html_response(conn, 200)

        weekday_checked? = result =~ "<input checked=\"checked\" class=\"subscription-day-checkbox\" id=\"subscription_weekday\" name=\"subscription[relevant_days][]\" type=\"checkbox\" value=\"weekday\">"
        sunday_unchecked? = result =~ "<input class=\"subscription-day-checkbox\" id=\"subscription_sunday\" name=\"subscription[relevant_days][]\" type=\"checkbox\" value=\"sunday\">"

        assert result =~ "Subscribe to station parking alerts"

        assert weekday_checked?
        assert sunday_unchecked?
      end
    end

    test "PATCH /subscriptions/parking/:id", %{conn: conn, user: user} do
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.list_enqueue([notification])
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, parking_subscription_entities())
        |> parking_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "relevant_days" => ["saturday"],
      }}

      use_cassette "parking_update", clear_mock: true  do
        conn = patch(conn, "/subscriptions/parking/#{subscription.id}", params)
        assert html_response(conn, 302) =~ "my-subscriptions"
        assert :error = HoldingQueue.pop()
      end
    end

    test "PATCH /subscriptions/parking/:id with incomplete params", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, parking_subscription_entities())
        |> parking_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "relevant_days" => [],
      }}

      conn = patch(conn, "/subscriptions/parking/#{subscription.id}", params)

      expected_error = "Please correct the following errors to proceed: At least one travel day must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 302) =~ "/subscriptions/parking/#{subscription.id}/edit"
      assert expected_error == error
    end

    test "PATCH /subscriptions/parking/:id with empty params", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, parking_subscription_entities())
        |> parking_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => [],
        "relevant_days" => [],
      }}

      conn = patch(conn, "/subscriptions/parking/#{subscription.id}", params)

      expected_error = "Please correct the following errors to proceed: At least one station must be selected. At least one travel day must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 302) =~ "/subscriptions/parking/#{subscription.id}/edit"
      assert expected_error == error
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/parking/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/parking/new")
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp login_user(%{conn: c}) do
    user = insert(:user)
    conn = guardian_login(user, c)
    {:ok, [conn: conn, user: user]}
  end
end
