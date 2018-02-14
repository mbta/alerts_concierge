defmodule ConciergeSite.AccessibilitySubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{HoldingQueue, Model.Subscription, Model.InformedEntity, Repo}

  describe "authorized" do
    setup :login_user

    test "GET /subscriptions/accessibility/new", %{conn: conn}  do
      conn = conn
      |> get("/subscriptions/accessibility/new")

      assert html_response(conn, 200) =~ "Create a new alert"
    end

    test "POST /subscriptions/accessibility with valid params", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "accessibility" => ["elevator"],
        "relevant_days" => ["saturday"],
        "routes" => ["blue"]
      }}

      conn = conn
      |> post("/subscriptions/accessibility", params)

      subscriptions = Repo.all(Subscription)

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert length(subscriptions) == 1
    end

    test "POST /subscriptions/accessibility with invalid params", %{conn: conn} do
      params = %{"subscription" => %{
        "accessibility" => [],
        "relevant_days" => [],
        "routes" => []
      }}

      conn = conn
      |> post("/subscriptions/accessibility", params)

      expected_error = "Please correct the following errors to proceed: At least one station or line must be selected. At least one travel day must be selected. At least one accessibility must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 200) =~ "Create a new alert"
      assert expected_error == error
    end

    test "POST /subscriptions/accessibility with invalid params with stations selected", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "accessibility" => [],
        "relevant_days" => [],
        "routes" => ["blue"]
      }}

      conn = post(conn, "/subscriptions/accessibility", params)

      expected_error = "Please correct the following errors to proceed: At least one travel day must be selected. At least one accessibility must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 200) =~ "Create a new alert"
      assert html_response(conn, 200) =~ "North Quincy"
      assert html_response(conn, 200) =~ "Forest Hills"
      assert expected_error == error
    end

    test "GET /subscriptions/accessibility/:id/edit", %{conn: conn, user: user} do
      accessibility_subscription_entities =     [
        %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"},
        %InformedEntity{route_type: 4, facility_type: :elevator, stop: "place-nqncy"}
      ]

      sub = subscription_factory()
      |> Map.put(:informed_entities, accessibility_subscription_entities)
      |> accessibility_subscription()
      |> weekday_subscription()
      |> Map.merge(%{user: user})
      |> insert()

      use_cassette "accessibility_update", clear_mock: true  do
        conn = get(conn, accessibility_subscription_path(conn, :edit, sub.id))
        result = html_response(conn, 200)

        green_line_checked? = result =~ "<input checked=\"checked\" class=\"subscription-day-checkbox\" id=\"subscription_green\" name=\"subscription[routes][]\" type=\"checkbox\" value=\"green\">"
        red_line_unchecked? = result =~ "<input class=\"subscription-day-checkbox\" id=\"subscription_red\" name=\"subscription[routes][]\" type=\"checkbox\" value=\"red\">"
        elevator_checked? = result =~ "<input checked=\"checked\" class=\"subscription-day-checkbox\" id=\"subscription_elevator\" name=\"subscription[accessibility][]\" type=\"checkbox\" value=\"elevator\">"
        escalator_unchecked? = result =~ "<input class=\"subscription-day-checkbox\" id=\"subscription_escalator\" name=\"subscription[accessibility][]\" type=\"checkbox\" value=\"escalator\">"
        weekday_checked? = result =~ "<input checked=\"checked\" class=\"subscription-day-checkbox\" id=\"subscription_weekday\" name=\"subscription[relevant_days][]\" type=\"checkbox\" value=\"weekday\">"
        sunday_unchecked? = result =~ "<input class=\"subscription-day-checkbox\" id=\"subscription_sunday\" name=\"subscription[relevant_days][]\" type=\"checkbox\" value=\"sunday\">"

        assert result =~ "Subscribe to station accessibility alerts"

        assert green_line_checked?
        assert red_line_unchecked?
        assert elevator_checked?
        assert escalator_unchecked?
        assert weekday_checked?
        assert sunday_unchecked?
      end
    end

    test "PATCH /subscriptions/accessibility/:id", %{conn: conn, user: user} do
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.list_enqueue([notification])
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, accessibility_subscription_entities())
        |> accessibility_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "accessibility" => ["elevator"],
        "relevant_days" => ["saturday"],
        "routes" => ["blue"]
      }}

      use_cassette "accessibility_update", clear_mock: true  do
        conn = patch(conn, "/subscriptions/accessibility/#{subscription.id}", params)
        assert html_response(conn, 302) =~ "my-subscriptions"
        assert :error = HoldingQueue.pop()
      end
    end

    test "PATCH /subscriptions/accessibility/:id with incomplete params", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, accessibility_subscription_entities())
        |> accessibility_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => ["place-nqncy", "place-forhl"],
        "accessibility" => [],
        "relevant_days" => [],
        "routes" => ["blue"]
      }}

      conn = patch(conn, "/subscriptions/accessibility/#{subscription.id}", params)

      expected_error = "Please correct the following errors to proceed: At least one travel day must be selected. At least one accessibility must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 302) =~ "/subscriptions/accessibility/#{subscription.id}/edit"
      assert expected_error == error
    end

    test "PATCH /subscriptions/accessibility/:id with empty params", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, accessibility_subscription_entities())
        |> accessibility_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> PaperTrail.insert!()

      params = %{"subscription" => %{
        "stops" => [],
        "accessibility" => [],
        "relevant_days" => [],
        "routes" => []
      }}

      conn = patch(conn, "/subscriptions/accessibility/#{subscription.id}", params)

      expected_error = "Please correct the following errors to proceed: At least one station or line must be selected. At least one travel day must be selected. At least one accessibility must be selected."
      error =
        conn
        |> get_flash("error")
        |> IO.iodata_to_binary()

      assert html_response(conn, 302) =~ "/subscriptions/accessibility/#{subscription.id}/edit"
      assert expected_error == error
    end
  end

  describe "unauthorized" do
    test "GET /subscriptions/accessibility/new", %{conn: conn} do
      conn = get(conn, "/subscriptions/accessibility/new")
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp login_user(%{conn: c}) do
    user = insert(:user)
    conn = guardian_login(user, c)
    {:ok, [conn: conn, user: user]}
  end
end
