defmodule ConciergeSite.AccessibilityTripControllerTest do
  use ConciergeSite.ConnCase

  setup do
    user = insert(:user)
    {:ok, user: user}
  end

  test "GET /accessibility_trips/new", %{conn: conn, user: user} do
    conn =
      user
      |> guardian_login(conn)
      |> get(accessibility_trip_path(conn, :new))

    assert html_response(conn, 200) =~ "accessibility"
  end

  describe "POST /accessibility_trips" do
    test "success", %{conn: conn, user: user} do
      trip = %{
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        stops: ["place-pktrm"],
        elevator: "true",
        escalator: "false",
        routes: ["Red~~Red Line~~subway"]
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(accessibility_trip_path(conn, :create), %{trip: trip})

      redir_path = "/trips"
      assert html_response(conn, 302) =~ redir_path
      conn = get(recycle(conn), redir_path)
      assert html_response(conn, 200) =~ "Success! Your subscription has been created."
    end

    test "failure", %{conn: conn, user: user} do
      trip = %{
        relevant_days: [],
        stops: [],
        elevator: "false",
        escalator: "false",
        routes: []
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(accessibility_trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 200) =~ "Please correct the error and re-submit."
    end
  end

  describe "GET /accessibility_trips/:id/edit" do
    test "with valid trip", %{conn: conn, user: user} do
      trip = insert(:trip, %{trip_type: :accessibility, user: user})

      conn =
        user
        |> guardian_login(conn)
        |> get(accessibility_trip_path(conn, :edit, trip.id))

      assert html_response(conn, 200) =~ "Edit subscription"
    end

    test "returns 404 with non-existent trip", %{conn: conn, user: user} do
      non_existent_trip_id = "ba51f08c-ad36-4dd5-a81a-557168c42f51"

      conn =
        user
        |> guardian_login(conn)
        |> get(accessibility_trip_path(conn, :edit, non_existent_trip_id))

      assert html_response(conn, 404) =~ "cannot be found"
    end

    test "returns 404 if user doesn't own trip", %{conn: conn, user: user} do
      sneaky_user = insert(:user, email: "sneaky_user@emailprovider.com")
      trip = insert(:trip, user: user)

      conn =
        sneaky_user
        |> guardian_login(conn)
        |> get(accessibility_trip_path(conn, :edit, trip.id))

      assert html_response(conn, 404) =~ "cannot be found"
    end
  end

  describe "PATCH /trips/:id" do
    test "with valid relevant days", %{conn: conn, user: user} do
      trip = insert(:trip, %{trip_type: :accessibility, user: user})

      params = [
        trip: %{
          relevant_days: [:tuesday, :thursday]
        }
      ]

      conn =
        user
        |> guardian_login(conn)
        |> patch(accessibility_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 200) =~ "Subscription updated."
    end

    test "with invalid relevant day", %{conn: conn, user: user} do
      trip = insert(:trip, %{trip_type: :accessibility, user: user})
      params = [trip: %{relevant_days: [:invalid]}]

      conn =
        user
        |> guardian_login(conn)
        |> patch(accessibility_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 422) =~ "Trip could not be updated."
    end

    test "with no relevant days selected to update", %{conn: conn, user: user} do
      trip = insert(:trip, %{trip_type: :accessibility, user: user})
      params = [trip: %{}]

      conn =
        user
        |> guardian_login(conn)
        |> patch(accessibility_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 422) =~ "Trip could not be updated."
      assert html_response(conn, 422) =~ "should have at least 1"
    end
  end
end
