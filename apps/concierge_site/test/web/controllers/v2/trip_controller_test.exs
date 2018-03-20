defmodule ConciergeSite.V2.TripControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory

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
      trip = insert(:trip, %{user_id: user.id})
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
      trip = insert(:trip, user_id: user.id)
      conn =
        sneaky_user
        |> guardian_login(conn)
        |> get(v2_trip_path(conn, :edit, trip.id))

      assert html_response(conn, 404) =~ "cannot be found"
    end
  end

  test "PATCH /v2/trips/:id", %{conn: conn, user: user} do
    trip = insert(:trip, %{user_id: user.id})
    conn = user
    |> guardian_login(conn)
    |> patch(v2_trip_path(conn, :update, trip.id, %{}))

    assert html_response(conn, 200) =~ "Edit Subscription"
  end

  test "DELETE /v2/trips/:id", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> delete(v2_trip_path(conn, :delete, "id"))

    assert html_response(conn, 302) =~ v2_trip_path(conn, :index)
  end

  test "GET /v2/trip/new", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_path(conn, :new))

    assert html_response(conn, 200) =~ "Is this usually a round trip?"
    assert html_response(conn, 200) =~ "Which route or line do you connect to?"
  end

  test "POST /v2/trip", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_path(conn, :create), %{})

    assert html_response(conn, 200) =~ "Is this usually a round trip?"
    assert html_response(conn, 200) =~ "Which route or line do you connect to?"
  end

  test "POST /v2/trip/leg to create new trip leg", %{conn: conn, user: user} do
    trip = %{
      destination: "place-pktrm",
      new_leg: "true",
      origin: "place-alfcl",
      round_trip: "true",
      route: "Green~~Green Line~~subway",
      saved_leg: "Red"
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
      legs: ["Blue"],
      origins: ["place-wondl"],
      destinations: ["place-state"]
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
      saved_leg: "Red"
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
      round_trip: "true"
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
