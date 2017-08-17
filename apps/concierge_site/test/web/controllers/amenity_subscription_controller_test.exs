defmodule ConciergeSite.AmenitySubscriptionControllerTest do
  use ConciergeSite.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{HoldingQueue, Model.Subscription, Repo}

  describe "authorized" do
    setup :login_user

    test "GET /subscriptions/amenities/new", %{conn: conn}  do
      conn = conn
      |> get("/subscriptions/amenities/new")

      assert html_response(conn, 200) =~ "Create New Subscription"
    end

    test "POST /subscriptions/amenities/add_station appends station to list", %{conn: conn} do
      route_id = "place-forhl"
      params = %{"subscription" => %{
        "stops" => "",
        "station" => route_id
      }}
      conn = conn
      |> post("/subscriptions/amenities/add_station", params)

      expected = "formaction=\"/subscriptions/amenities/remove_station/Forest%20Hills\""

      assert html_response(conn, 200) =~ expected
    end

    test "POST /subscriptions/amenities/add_station does not append duplicates", %{conn: conn} do
      route_id = "place-forhl"
      params = %{"subscription" => %{
        "stops" => "",
        "station" => route_id
      }}

      post(conn, "/subscriptions/amenities/add_station", params)

      params = %{"subscription" => %{
        "stops" => route_id,
        "station" => route_id
      }}

      conn = conn
      |> post("/subscriptions/amenities/add_station", params)

      expected = ~r/formaction=\"\/subscriptions\/amenities\/remove_station\/Forest%20Hills\"/
      result = html_response(conn, 200)
      number_of_matches = length(Regex.scan(expected, result))

      assert number_of_matches == 1
    end

    test "POST /subscriptions/amenities/remove_station removes station from list", %{conn: conn} do
      route_id = "place-forhl"
      params = %{"subscription" => %{
        "stops" => route_id
      }}

      conn = conn
      |> post("/subscriptions/amenities/remove_station/#{route_id}", params)

      station_link = "formaction=\"/subscriptions/amenities/remove_station/Forest%20Hills\" type=\"submit\">\nForest Hills"

      refute html_response(conn, 200) =~ station_link
    end

    test "POST /subscriptions/amenities with valid params", %{conn: conn} do
      params = %{"subscription" => %{
        "stops" => "North Quincy,Forest Hills",
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
        "stops" => "",
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

    test "GET /subscriptions/amenities/:id/edit", %{conn: conn, user: user} do
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, amenity_subscription_entities())
        |> amenity_subscription()
        |> weekday_subscription()
        |> Map.merge(%{user: user})
        |> insert()

      use_cassette "amenities_update", clear_mock: true  do
        conn = get(conn, "/subscriptions/amenities/#{subscription.id}/edit")
        assert html_response(conn, 200) =~ "Subscribe to station amenity alerts"
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
        |> insert()

      params = %{"subscription" => %{
        "stops" => "North Quincy,Forest Hills",
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

    test "PATCH /subscriptions/amenities/add_station", %{conn: conn, user: user} do
      sub = subscription_factory()
      |> Map.put(:informed_entities, amenity_subscription_entities())
      |> amenity_subscription()
      |> weekday_subscription()
      |> Map.merge(%{user: user})
      |> insert()

      params = %{
        "subscription" => %{
          "stops" => "North Quincy",
          "amenities" => ["elevator"],
          "relevant_days" => ["saturday"],
          "routes" => ["blue"],
          "station" => "place-forhl",
          "id" => sub.id
        },
      }

      station_link = "formaction=\"/subscriptions/amenities/remove_station/Forest%20Hills\" type=\"submit\">"

      use_cassette "amenities_update", clear_mock: true  do
        conn = patch(conn, "/subscriptions/amenities/add_station", params)
        assert html_response(conn, 200) =~ station_link
      end
    end

    test "PATCH /subscriptions/amenities/remove_station/:station", %{conn: conn, user: user} do
      sub = subscription_factory()
      |> Map.put(:informed_entities, amenity_subscription_entities())
      |> amenity_subscription()
      |> weekday_subscription()
      |> Map.merge(%{user: user})
      |> insert()

      params = %{
        "subscription" => %{
          "stops" => "North Quincy,Forest Hills",
          "amenities" => ["elevator"],
          "relevant_days" => ["saturday"],
          "routes" => ["blue"],
          "id" => sub.id
        },
        "station" => "Forest Hills"
      }

      station_link = "formaction=\"/subscriptions/amenities/remove_station/Forest%20Hills\" type=\"submit\">\nForest Hills"

      use_cassette "amenities_update", clear_mock: true  do
        conn = patch(conn, "/subscriptions/amenities/remove_station/Forest%20Hills", params)
        refute html_response(conn, 200) =~ station_link
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
