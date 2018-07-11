defmodule ConciergeSite.V2.TripControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory
  alias AlertProcessor.Model.Trip

  setup do
    user = insert(:user)

    {:ok, user: user}
  end

  test "GET /trips", %{conn: conn, user: user} do
    conn =
      user
      |> guardian_login(conn)
      |> get(v2_trip_path(conn, :index))

    assert html_response(conn, 200) =~ "My subscriptions"
  end

  describe "GET /trips/:id/edit" do
    test "with valid trip", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})

      insert(:subscription, %{
        trip_id: trip.id,
        type: :cr,
        origin: "Readville",
        destination: "Newmarket",
        route: "CR-Fairmount"
      })

      insert(:subscription, %{
        trip_id: trip.id,
        type: :subway,
        origin: "place-chncl",
        destination: "place-ogmnl",
        route: "Orange"
      })

      insert(:subscription, %{trip_id: trip.id, type: :bus, route: "741"})

      conn =
        user
        |> guardian_login(conn)
        |> get(v2_trip_path(conn, :edit, trip.id))

      assert html_response(conn, 200) =~ "Edit subscription"
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

  describe "PATCH /trips/:id" do
    test "with HH:MM time format", %{conn: conn, user: user} do
      # Time format comes through with `HH:MM` format after a user updates them
      # in the trip edit page.
      trip = insert(:trip, %{user: user})

      params = [
        trip: %{
          relevant_days: [:tuesday, :thursday],
          start_time: "1:30 PM",
          end_time: "2:00 PM",
          return_start_time: "3:30 PM",
          return_end_time: "4:00 PM"
        }
      ]

      conn =
        user
        |> guardian_login(conn)
        |> patch(v2_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 302) =~ v2_trip_path(conn, :index)
    end

    test "with HH:MM:SS time format", %{conn: conn, user: user} do
      # Time is sent with `HH:MM:SS` format if the user doesn't update them.
      # They come through with `HH:MM` format if they do update them. So we
      # need to correctly handle both formats.
      trip = insert(:trip, %{user: user})

      params = [
        trip: %{
          relevant_days: [:tuesday, :thursday],
          start_time: "1:30 PM",
          end_time: "2:00 PM",
          return_start_time: "3:30 PM",
          return_end_time: "4:00 PM"
        }
      ]

      conn =
        user
        |> guardian_login(conn)
        |> patch(v2_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 302) =~ v2_trip_path(conn, :index)
    end

    test "with invalid relevant day", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})
      insert(:subscription, %{
        trip_id: trip.id,
        type: :cr,
        origin: "Readville",
        destination: "Newmarket",
        route: "CR-Fairmount"
      })
      params = [trip: %{relevant_days: [:invalid]}]

      conn =
        user
        |> guardian_login(conn)
        |> patch(v2_trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 422) =~ "Trip could not be updated."
    end
  end

  describe "DELETE /trips/:id" do
    test "deletes trip and redirects to trip index page", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})

      conn =
        user
        |> guardian_login(conn)
        |> delete(v2_trip_path(conn, :delete, trip.id))

      assert html_response(conn, 302) =~ v2_trip_path(conn, :index)
      refute Trip.find_by_id(trip.id)
    end

    test "returns 404 with non-existent trip", %{conn: conn, user: user} do
      non_existent_trip_id = Ecto.UUID.generate()

      conn =
        user
        |> guardian_login(conn)
        |> delete(v2_trip_path(conn, :delete, non_existent_trip_id))

      assert html_response(conn, 404) =~ "cannot be found"
    end

    test "returns 404 if user is not the owner of the trip", %{conn: conn, user: sneaky_user} do
      owner = insert(:user)
      trip = insert(:trip, %{user: owner})

      conn =
        sneaky_user
        |> guardian_login(conn)
        |> delete(v2_trip_path(conn, :delete, trip.id))

      assert html_response(conn, 404) =~ "cannot be found"
      assert Trip.find_by_id(trip.id)
    end
  end

  test "GET /trip/new (first)", %{conn: conn, user: user} do
    conn =
      user
      |> guardian_login(conn)
      |> get(v2_trip_path(conn, :new))

    assert html_response(conn, 200) =~ "What kind of trip is this?"
    assert html_response(conn, 200) =~ "Which line or route do you take first?"
    assert html_response(conn, 200) =~ "Once we get to know more about your trips"
  end

  test "GET /trip/new (subsequent)", %{conn: conn, user: user} do
    insert(:trip, %{user: user})

    conn =
      user
      |> guardian_login(conn)
      |> get(v2_trip_path(conn, :new))

    refute html_response(conn, 200) =~ "Once we get to know more about your trips"
  end

  describe "POST /trip" do
    test "subway", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        destinations: ["place-pktrm"],
        elevator: "true",
        end_time: "12:00 PM",
        escalator: "false",
        legs: ["Red"],
        modes: ["subway"],
        origins: ["place-alfcl"],
        parking_area: "true",
        return_end_time: "6:00 PM",
        return_start_time: "5:00 PM",
        round_trip: "true",
        start_time: "12:00 AM"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(v2_trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ v2_trip_path(conn, :index)

      conn = get(conn, v2_trip_path(conn, :index))

      html = html_response(conn, 200)
      assert html =~ "Success! Your subscription has been created."

      assert html =~ "Red Line"
      assert html =~ "Round-trip"
      assert html =~ "12:00A - 12:00P,  5:00P -  6:00P"
    end

    test "green line multi-route", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        destinations: ["place-gover"],
        elevator: "true",
        end_time: "9:00 AM",
        escalator: "false",
        legs: ["Green"],
        modes: ["subway"],
        origins: ["place-boyls"],
        parking_area: "true",
        return_end_time: "6:00 PM",
        return_start_time: "5:00 PM",
        round_trip: "true",
        start_time: "8:00 AM"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(v2_trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ v2_trip_path(conn, :index)

      conn = get(conn, v2_trip_path(conn, :index))

      assert html_response(conn, 200) =~ "Success! Your subscription has been created."

      assert html_response(conn, 200) =~ "Green Line"
      refute html_response(conn, 200) =~ "Green Line D"
      refute html_response(conn, 200) =~ "Green Line D"
      refute html_response(conn, 200) =~ "Green Line E"
    end

    test "green line single-route", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        destinations: ["place-north"],
        elevator: "true",
        end_time: "9:00 AM",
        escalator: "false",
        legs: ["Green"],
        modes: ["subway"],
        origins: ["place-lech"],
        parking_area: "true",
        return_end_time: "6:00 PM",
        return_start_time: "5:00 PM",
        round_trip: "true",
        start_time: "8:00 AM"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(v2_trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ v2_trip_path(conn, :index)

      conn = get(conn, v2_trip_path(conn, :index))

      assert html_response(conn, 200) =~ "Success! Your subscription has been created."

      refute html_response(conn, 200) =~ "Green Line C"
      assert html_response(conn, 200) =~ "Green Line E"
    end

    test "bus", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        destinations: [""],
        elevator: "false",
        end_time: "9:00 AM",
        escalator: "false",
        legs: ["741 - 1"],
        modes: ["bus"],
        origins: [""],
        parking: "false",
        return_end_time: "6:00 PM",
        return_start_time: "5:00 PM",
        round_trip: "true",
        start_time: "8:00 AM"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(v2_trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ v2_trip_path(conn, :index)

      conn = get(conn, v2_trip_path(conn, :index))

      assert html_response(conn, 200) =~
               "<span class=\"trip__card--route\">Silver Line SL1</span>"
    end

    test "returns error message with no day selected", %{conn: conn, user: user} do
      trip = %{
        # Note that ':relevant_days' is missing. This simulates somebody not
        # selecting a day.
        bike_storage: "false",
        destinations: [""],
        elevator: "false",
        end_time: "9:00 AM",
        escalator: "false",
        legs: ["741 - 1"],
        modes: ["bus"],
        origins: [""],
        parking: "false",
        return_end_time: "6:00 PM",
        return_start_time: "5:00 PM",
        round_trip: "true",
        start_time: "8:00 AM"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(v2_trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 200) =~ "You must select at least one day for your trip."
    end
  end

  test "POST /trip/leg to create new trip leg (orange)", %{conn: conn, user: user} do
    trip = %{
      destination: "place-forhl",
      new_leg: "true",
      origin: "place-dwnxg",
      round_trip: "true",
      route: "Orange~~Orange Line~~subway",
      saved_leg: "Red",
      saved_mode: "subway"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Orange Line?"
    assert html_response(conn, 200) =~ "Do you transfer to another route or line?"
    refute html_response(conn, 200) =~ "Only stops on the same branch can be selected"
  end

  test "POST /trip/leg to create new trip leg (Green)", %{conn: conn, user: user} do
    trip = %{
      destination: "place-pktrm",
      new_leg: "true",
      origin: "place-alfcl",
      round_trip: "true",
      route: "Green~~Green Line~~subway",
      saved_leg: "Red",
      saved_mode: "subway"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Green Line?"
    assert html_response(conn, 200) =~ "Do you transfer to another route, line, or branch?"
    assert html_response(conn, 200) =~ "Only stops on the same branch can be selected."
    assert html_response(conn, 200) =~ "selected=\"selected\" value=\"place-pktrm\">Park Street</option>"
  end

  test "leg/3 with same origin and destination", %{conn: conn, user: user} do
    stop = "some-stop"

    trip = %{
      destination: stop,
      new_leg: "true",
      origin: stop,
      round_trip: "true",
      route: "Green~~Green Line~~subway",
      saved_leg: "Red",
      saved_mode: "subway"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Trip origin and destination must be different."
  end

  test "POST /trip/leg to create new trip leg with existing trip legs", %{conn: conn, user: user} do
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

    conn =
      user
      |> guardian_login(conn)
      |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Green Line?"
    assert html_response(conn, 200) =~ "Do you transfer to another route, line, or branch?"
  end

  test "POST /trip/leg to finish trip", %{conn: conn, user: user} do
    trip = %{
      destination: "place-pktrm",
      new_leg: "false",
      origin: "place-alfcl",
      round_trip: "true",
      saved_leg: "Red",
      saved_mode: "subway"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "true"
    assert html_response(conn, 200) =~ "Red"
    assert html_response(conn, 200) =~ "place-alfcl"
    assert html_response(conn, 200) =~ "place-pktrm"
  end

  test "POST /trip/leg to create first leg", %{conn: conn, user: user} do
    trip = %{
      from_new_trip: "true",
      round_trip: "true",
      route: "Red~~Red Line~~subway"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(v2_trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Red Line?"
    assert html_response(conn, 200) =~ "Do you transfer to another route, line, or branch?"
  end

  test "POST /trip/leg with errors", %{conn: conn, user: user} do
    conn =
      user
      |> guardian_login(conn)
      |> post(v2_trip_trip_path(conn, :leg), %{trip: %{}})

    assert html_response(conn, 200) =~ "There was an error creating your trip. Please try again."
  end

  describe "POST /trip/times" do
    test "subway", %{conn: conn, user: user} do
      trip = %{
        destinations: ["place-pktrm"],
        legs: ["Red"],
        origins: ["place-alfcl"],
        round_trip: "true",
        modes: ["subway"]
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(v2_trip_trip_path(conn, :times), %{trip: trip})

      assert html_response(conn, 200) =~ "true"
      assert html_response(conn, 200) =~ "Red"
      assert html_response(conn, 200) =~ "place-alfcl"
      assert html_response(conn, 200) =~ "place-pktrm"
    end

    test "cr", %{conn: conn, user: user} do
      trip = %{
        destinations: ["Newmarket"],
        legs: ["CR-Fairmount"],
        origins: ["Readville"],
        round_trip: "true",
        modes: ["cr"],
        schedule_return: %{"CR-Fairmount" => ["17:45:00"]},
        schedule_start: %{"CR-Fairmount" => ["08:48:00"]}
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(v2_trip_trip_path(conn, :times), %{trip: trip})

      assert html_response(conn, 200) =~ "true"
      assert html_response(conn, 200) =~ "CR-Fairmount"
      assert html_response(conn, 200) =~ "Newmarket"
      assert html_response(conn, 200) =~ "Readville"
    end

    test "bus", %{conn: conn, user: user} do
      trip = %{
        destinations: [],
        legs: ["41 - 1"],
        origins: [],
        round_trip: "true",
        modes: ["bus"]
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(v2_trip_trip_path(conn, :times), %{trip: trip})

      assert html_response(conn, 200) =~ "true"
    end
  end

  describe "PUT /trips/:trip_id" do
    test "cr", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})

      insert(:subscription, %{
        trip_id: trip.id,
        type: :cr,
        origin: "Readville",
        destination: "Newmarket",
        route: "CR-Fairmount",
        user_id: user.id
      })

      data = %{
        "end_time" => "9:00 AM",
        "relevant_days" => ["monday", "tuesday", "wednesday", "thursday", "friday"],
        "return_end_time" => "6:00 PM",
        "return_start_time" => "5:00 PM",
        "schedule_return" => %{"CR-Fairmount" => ["17:45:00"]},
        "schedule_start" => %{"CR-Fairmount" => ["08:48:00"]},
        "start_time" => "8:00 AM"
      }

      conn =
        user
        |> guardian_login(conn)
        |> put("/trips/#{trip.id}", %{trip: data})

      assert html_response(conn, 302) =~ "redirected"
    end
  end
end
