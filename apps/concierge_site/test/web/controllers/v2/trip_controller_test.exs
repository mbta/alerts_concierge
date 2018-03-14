defmodule ConciergeSite.V2.TripControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory
  alias AlertProcessor.Model.Trip

  setup do
    user = insert(:user)

    {:ok, user: user}
  end

  test "GET /v2/trips", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_path(conn, :index))

    assert html_response(conn, 200) =~ "My account"
  end

  describe "GET /v2/trips/:id/edit" do
    test "with valid trip", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})
      conn =
        user
        |> guardian_login(conn)
        |> get(v2_trip_path(conn, :edit, trip.id))

      assert html_response(conn, 200) =~ "Edit Subscription"
    end

    test "returns 404 with non-existent trip", %{conn: conn, user: user} do
      non_existent_trip_id = "ba51f08c-ad36-4dd5-a81a-557168c42f51"
      conn =
        user
        |> guardian_login(conn)
        |> get(v2_trip_path(conn, :edit, non_existent_trip_id))

      assert html_response(conn, 404) =~ "cannot be found"
    end

    test "returns 404 if user doesn't own trip", %{conn: conn, user: user} do
      sneaky_user = insert(:user, email: "sneaky_user@emailprovider.com")
      trip = insert(:trip, user: user)
      conn =
        sneaky_user
        |> guardian_login(conn)
        |> get(v2_trip_path(conn, :edit, trip.id))

      assert html_response(conn, 404) =~ "cannot be found"
    end
  end

  describe "PATCH /v2/trips/:id" do
    test "with HH:MM time format", %{conn: conn, user: user} do
      # Time format comes through with `HH:MM` format after a user updates them
      # in the trip edit page.
      trip = insert(:trip, %{user: user})
      params = [
        trip: %{
          relevant_days: [:tuesday, :thursday],
          start_time: "13:30",
          end_time: "14:00",
          return_start_time: "15:30",
          return_end_time: "16:00",
          alert_time_difference_in_minutes: 30
        }
      ]
      conn = user
             |> guardian_login(conn)
             |> patch(v2_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 200) =~ "Trip updated."
    end

    test "with HH:MM:SS time format", %{conn: conn, user: user} do
      # Time is sent with `HH:MM:SS` format if the user doesn't update them.
      # They come through with `HH:MM` format if they do update them. So we
      # need to correctly handle both formats.
      trip = insert(:trip, %{user: user})
      params = [
        trip: %{
          relevant_days: [:tuesday, :thursday],
          start_time: "13:30:00",
          end_time: "14:00:00",
          return_start_time: "15:30:00",
          return_end_time: "16:00:00",
          alert_time_difference_in_minutes: 30
        }
      ]
      conn = user
             |> guardian_login(conn)
             |> patch(v2_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 200) =~ "Trip updated."
    end

    test "with invalid relevant day", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})
      params = [trip: %{relevant_days: [:invalid]}]
      conn = user
             |> guardian_login(conn)
             |> patch(v2_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 422) =~ "Trip could not be updated."
    end
  end

  describe "DELETE /v2/trips/:id" do
    test "deletes trip and redirects to trip index page", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})
      conn = user
             |> guardian_login(conn)
             |> delete(v2_trip_path(conn, :delete, trip.id))

      assert html_response(conn, 302) =~ v2_trip_path(conn, :index)
      refute Trip.find_by_id(trip.id)
    end

    test "returns 404 with non-existent trip", %{conn: conn, user: user} do
      non_existent_trip_id = Ecto.UUID.generate()
      conn = user
             |> guardian_login(conn)
             |> delete(v2_trip_path(conn, :delete, non_existent_trip_id))

      assert html_response(conn, 404) =~ "cannot be found"
    end

    test "returns 404 if user is not the owner of the trip", %{conn: conn, user: sneaky_user} do
      owner = insert(:user)
      trip = insert(:trip, %{user: owner})
      conn = sneaky_user
             |> guardian_login(conn)
             |> delete(v2_trip_path(conn, :delete, trip.id))

      assert html_response(conn, 404) =~ "cannot be found"
      assert Trip.find_by_id(trip.id)
    end
  end

  test "GET /v2/trip/new", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_path(conn, :new))

    assert html_response(conn, 200) =~ "Is this usually a round trip?"
    assert html_response(conn, 200) =~ "Which route or line do you connect to?"
  end

  test "POST /v2/trip subway", %{conn: conn, user: user} do
    trip = %{
      bike_storage: "false",
      days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
      destinations: ["place-pktrm"],
      elevator: "false",
      end_time: "09:00",
      escalator: "false",
      legs: ["Red"],
      modes: ["subway"],
      origins: ["place-alfcl"],
      parking: "false",
      return_end_time: "18:00",
      return_start_time: "17:00",
      round_trip: "true",
      start_time: "08:00"
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_path(conn, :create), %{trip: trip})

    assert html_response(conn, 302) =~ v2_trip_path(conn, :index)

    conn = get(conn, v2_trip_path(conn, :index))

    assert html_response(conn, 200) =~ "Success! If at any time you need to edit the features, "
    <> "stations, or lines you&#39;ve subscribed to, you can click in the box below."

    assert html_response(conn, 200) =~ "<span class=\"trip__card--route\">Red</span>"
    <> "<div class=\"trip__card--type my-2\">Round-trip, Weekdays</div>"
    <> "<div class=\"trip__card--times\"> 8:00am -  9:00am /  5:00pm -  6:00pm</div>"
  end

  test "POST /v2/trip bus", %{conn: conn, user: user} do
    trip = %{
      bike_storage: "false",
      days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
      destinations: [""],
      elevator: "false",
      end_time: "09:00",
      escalator: "false",
      legs: ["741 - 1"],
      modes: ["bus"],
      origins: [""],
      parking: "false",
      return_end_time: "18:00",
      return_start_time: "17:00",
      round_trip: "true",
      start_time: "08:00"
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_path(conn, :create), %{trip: trip})

    assert html_response(conn, 302) =~ v2_trip_path(conn, :index)

    conn = get(conn, v2_trip_path(conn, :index))

    assert html_response(conn, 200) =~ "<span class=\"trip__card--route\">741</span>"
  end

  test "POST /v2/trip/leg to create new trip leg", %{conn: conn, user: user} do
    trip = %{
      destination: "place-pktrm",
      new_leg: "true",
      origin: "place-alfcl",
      round_trip: "true",
      route: "Green~~Green Line~~subway",
      saved_leg: "Red",
      saved_mode: "subway"
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Green Line?"
    assert html_response(conn, 200) =~ "Do you make a connection to another route or line?"
  end

  test "POST /v2/trip/leg to create new trip leg with existing trip legs", %{conn: conn, user: user} do
    trip = %{
      destination: "place-pktrm",
      new_leg: "true",
      origin: "place-alfcl",
      round_trip: "true",
      route: "Green~~Green Line~~subway",
      saved_leg: "Red",
      saved_mode: "subway",
      legs: ["Blue"],
      origins: ["place-wondl"],
      destinations: ["place-state"],
      modes: ["subway"]
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Green Line?"
    assert html_response(conn, 200) =~ "Do you make a connection to another route or line?"
  end

  test "POST /v2/trip/leg to finish trip", %{conn: conn, user: user} do
    trip = %{
      destination: "place-pktrm",
      new_leg: "false",
      origin: "place-alfcl",
      round_trip: "true",
      saved_leg: "Red",
      saved_mode: "subway"
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "true"
    assert html_response(conn, 200) =~ "Red"
    assert html_response(conn, 200) =~ "place-alfcl"
    assert html_response(conn, 200) =~ "place-pktrm"
  end

  test "POST /v2/trip/leg to create first leg", %{conn: conn, user: user} do
    trip = %{
      from_new_trip: "true",
      round_trip: "true",
      route: "Red~~Red Line~~subway"
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Red Line?"
    assert html_response(conn, 200) =~ "Do you make a connection to another route or line?"
  end

  test "POST /v2/trip/leg with errors", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_trip_path(conn, :leg), %{trip: %{}})

    assert html_response(conn, 200) =~ "There was an error creating your trip. Please try again."
  end

  test "POST /v2/trip/times", %{conn: conn, user: user} do
    trip = %{
      destinations: ["place-pktrm"],
      legs: ["Red"],
      origins: ["place-alfcl"],
      round_trip: "true",
      modes: ["subway"]
    }

    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_trip_path(conn, :times), %{trip: trip})

    assert html_response(conn, 200) =~ "true"
    assert html_response(conn, 200) =~ "Red"
    assert html_response(conn, 200) =~ "place-alfcl"
    assert html_response(conn, 200) =~ "place-pktrm"
  end

  test "GET /v2/trip/accessibility", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_trip_path(conn, :accessibility))

    assert html_response(conn, 200) =~ "accessibility"
  end
end
