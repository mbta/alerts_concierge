defmodule ConciergeSite.AmenitySubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{HoldingQueue, Model.Subscription, Model.InformedEntity, Repo}

  describe "authorized" do
    setup :login_user

    test "GET /subscriptions/amenities/new", %{conn: conn}  do
      conn = conn
      |> get("/subscriptions/amenities/new")

      assert html_response(conn, 200) =~ "Create New Subscription"
    end

    test "POST /subscriptions/amenities with valid params", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "amenities" => ["elevator"],
        "relevant_days" => ["saturday"],
        "routes" => ["blue"]
      }}

      conn = conn
      |> post("/subscriptions/amenities", params)

      subscriptions = Repo.all(Subscription)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert length(subscriptions) == 1
    end

    test "POST /subscriptions/amenities with invalid params", %{conn: conn} do
      params = %{"subscription" => %{
        "amenities" => [],
        "relevant_days" => [],
        "routes" => []
      }}

      conn = conn
      |> post("/subscriptions/amenities", params)

      expected_error = "Please correct the following errors to proceed: At least one station or line must be selected. At least one travel day must be selected. At least one amenity must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 200) =~ "Create New Subscription"
      assert expected_error == error
    end

    test "POST /subscriptions/amenities with invalid params with stations selected", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "amenities" => [],
        "relevant_days" => [],
        "routes" => ["blue"]
      }}

      conn = conn
      |> post("/subscriptions/amenities", params)

      expected_error = "Please correct the following errors to proceed: At least one travel day must be selected. At least one amenity must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 200) =~ "Create New Subscription"
      assert html_response(conn, 200) =~ "North Quincy"
      assert html_response(conn, 200) =~ "Forest Hills"
      assert expected_error == error
    end

    test "GET /subscriptions/amenities/:id/edit", %{conn: conn, user: user} do
      amenity_subscription_entities =     [
        %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"},
        %InformedEntity{route_type: 4, facility_type: :elevator, stop: "place-nqncy"}
      ]

      sub = subscription_factory()
      |> Map.put(:informed_entities, amenity_subscription_entities)
      |> amenity_subscription()
      |> weekday_subscription()
      |> Map.merge(%{user: user})
      |> insert()

      use_cassette "amenities_update", clear_mock: true  do
        conn = get(conn, amenity_subscription_path(conn, :edit, sub.id))
        result = html_response(conn, 200)

        green_line_checked? = result =~ "<input checked=\"checked\" class=\"subscription-day-checkbox\" id=\"subscription_green\" name=\"subscription[routes][]\" type=\"checkbox\" value=\"green\">"
        red_line_unchecked? = result =~ "<input class=\"subscription-day-checkbox\" id=\"subscription_red\" name=\"subscription[routes][]\" type=\"checkbox\" value=\"red\">"
        elevator_checked? = result =~ "<input checked=\"checked\" class=\"subscription-day-checkbox\" id=\"subscription_elevator\" name=\"subscription[amenities][]\" type=\"checkbox\" value=\"elevator\">"
        escalator_unchecked? = result =~ "<input class=\"subscription-day-checkbox\" id=\"subscription_escalator\" name=\"subscription[amenities][]\" type=\"checkbox\" value=\"escalator\">"
        weekday_checked? = result =~ "<input checked=\"checked\" class=\"subscription-day-checkbox\" id=\"subscription_weekday\" name=\"subscription[relevant_days][]\" type=\"checkbox\" value=\"weekday\">"
        sunday_unchecked? = result =~ "<input class=\"subscription-day-checkbox\" id=\"subscription_sunday\" name=\"subscription[relevant_days][]\" type=\"checkbox\" value=\"sunday\">"

        assert result =~ "Subscribe to station amenity alerts"

        assert green_line_checked?
        assert red_line_unchecked?
        assert elevator_checked?
        assert escalator_unchecked?
        assert weekday_checked?
        assert sunday_unchecked?
      end
    end

    test "PATCH /subscriptions/amenities/:id", %{conn: conn, user: user} do
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.enqueue(notification)
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, amenity_subscription_entities())
        |> amenity_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "amenities" => ["elevator"],
        "relevant_days" => ["saturday"],
        "routes" => ["blue"]
      }}

      use_cassette "amenities_update", clear_mock: true  do
        conn = patch(conn, "/subscriptions/amenities/#{subscription.id}", params)
        assert html_response(conn, 302) =~ "my-subscriptions"
        assert :error = HoldingQueue.pop()
      end
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/amenities/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/amenities/new")
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp login_user(%{conn: c}) do
    user = insert(:user)
    conn = guardian_login(user, c)
    {:ok, [conn: conn, user: user]}
  end
end
