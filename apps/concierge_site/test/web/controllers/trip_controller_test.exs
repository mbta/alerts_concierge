defmodule ConciergeSite.TripControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory
  alias AlertProcessor.Model.Trip

  setup do
    user = insert(:user)

    {:ok, user: user}
  end

  describe "GET /trips" do
    test "explains alerts are disabled", %{conn: conn} do
      user = insert(:user, communication_mode: "none")

      conn = user |> guardian_login(conn) |> get(trip_path(conn, :index))

      assert html_response(conn, 200) =~ "Alerts are disabled for your account"
    end

    test "has no message if alerts are not disabled", %{conn: conn, user: user} do
      conn = user |> guardian_login(conn) |> get(trip_path(conn, :index))

      response = html_response(conn, 200)

      assert response =~ "My subscriptions"
      refute response =~ "Alerts are disabled for your account"
    end
  end

  describe "GET /trips/:id/edit" do
    test "with valid trip", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})

      insert(:subscription, %{
        trip_id: trip.id,
        type: :cr,
        origin: "place-DB-0095",
        destination: "place-DB-2265",
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
        |> get(trip_path(conn, :edit, trip.id))

      assert html_response(conn, 200) =~ "Edit subscription"
    end

    test "returns 404 with non-existent trip", %{conn: conn, user: user} do
      non_existent_trip_id = "ba51f08c-ad36-4dd5-a81a-557168c42f51"

      conn =
        user
        |> guardian_login(conn)
        |> get(trip_path(conn, :edit, non_existent_trip_id))

      assert html_response(conn, 404) =~ "cannot be found"
    end

    test "returns 404 if user doesn't own trip", %{conn: conn, user: user} do
      sneaky_user = insert(:user, email: "sneaky_user@emailprovider.com")
      trip = insert(:trip, user: user)

      conn =
        sneaky_user
        |> guardian_login(conn)
        |> get(trip_path(conn, :edit, trip.id))

      assert html_response(conn, 404) =~ "cannot be found"
    end
  end

  describe "PATCH /trips/:id" do
    test "with map time format", %{conn: conn, user: user} do
      # Time format comes through with `HH:MM` format after a user updates them
      # in the trip edit page.
      trip = insert(:trip, %{user: user})

      params = [
        trip: %{
          relevant_days: [:tuesday, :thursday],
          start_time: %{"am_pm" => "PM", "hour" => "1", "minute" => "30"},
          end_time: %{"am_pm" => "PM", "hour" => "2", "minute" => "00"},
          return_start_time: %{"am_pm" => "PM", "hour" => "3", "minute" => "30"},
          return_end_time: %{"am_pm" => "PM", "hour" => "4", "minute" => "00"}
        }
      ]

      conn =
        user
        |> guardian_login(conn)
        |> patch(trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 302) =~ trip_path(conn, :index)
    end

    test "with invalid relevant day", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})

      insert(:subscription, %{
        trip_id: trip.id,
        type: :cr,
        origin: "place-DB-0095",
        destination: "place-DB-2265",
        route: "CR-Fairmount"
      })

      params = [trip: %{relevant_days: [:invalid]}]

      conn =
        user
        |> guardian_login(conn)
        |> patch(trip_path(conn, :update, trip.id, params))

      assert html_response(conn, 422) =~ "Trip could not be updated."
    end
  end

  describe "DELETE /trips/:id" do
    test "deletes trip and redirects to trip index page", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})

      conn =
        user
        |> guardian_login(conn)
        |> delete(trip_path(conn, :delete, trip.id))

      assert html_response(conn, 302) =~ trip_path(conn, :index)
      refute Trip.find_by_id(trip.id)
    end

    test "returns 404 with non-existent trip", %{conn: conn, user: user} do
      non_existent_trip_id = Ecto.UUID.generate()

      conn =
        user
        |> guardian_login(conn)
        |> delete(trip_path(conn, :delete, non_existent_trip_id))

      assert html_response(conn, 404) =~ "cannot be found"
    end

    test "returns 404 if user is not the owner of the trip", %{conn: conn, user: sneaky_user} do
      owner = insert(:user)
      trip = insert(:trip, %{user: owner})

      conn =
        sneaky_user
        |> guardian_login(conn)
        |> delete(trip_path(conn, :delete, trip.id))

      assert html_response(conn, 404) =~ "cannot be found"
      assert Trip.find_by_id(trip.id)
    end
  end

  test "GET /trip/new (first)", %{conn: conn, user: user} do
    conn =
      user
      |> guardian_login(conn)
      |> get(trip_path(conn, :new))

    assert html_response(conn, 200) =~ "What kind of trip is this?"
    assert html_response(conn, 200) =~ "Which line or route do you take first?"
    assert html_response(conn, 200) =~ "Once we get to know more about your trips"
  end

  test "GET /trip/new (subsequent)", %{conn: conn, user: user} do
    insert(:trip, %{user: user})

    conn =
      user
      |> guardian_login(conn)
      |> get(trip_path(conn, :new))

    refute html_response(conn, 200) =~ "Once we get to know more about your trips"
  end

  describe "POST /trip" do
    test "subway", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        destinations: ["place-pktrm"],
        elevator: "true",
        end_time: %{"am_pm" => "PM", "hour" => "12", "minute" => "00"},
        escalator: "false",
        legs: ["Red"],
        modes: ["subway"],
        origins: ["place-alfcl"],
        parking_area: "true",
        return_end_time: %{"am_pm" => "PM", "hour" => "6", "minute" => "00"},
        return_start_time: %{"am_pm" => "PM", "hour" => "5", "minute" => "00"},
        round_trip: "true",
        start_time: %{"am_pm" => "AM", "hour" => "12", "minute" => "00"}
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ trip_path(conn, :index)

      conn = get(conn, trip_path(conn, :index))

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
        end_time: %{"am_pm" => "AM", "hour" => "9", "minute" => "00"},
        escalator: "false",
        legs: ["Green"],
        modes: ["subway"],
        origins: ["place-boyls"],
        parking_area: "true",
        return_end_time: %{"am_pm" => "PM", "hour" => "6", "minute" => "00"},
        return_start_time: %{"am_pm" => "PM", "hour" => "5", "minute" => "00"},
        round_trip: "true",
        start_time: %{"am_pm" => "AM", "hour" => "8", "minute" => "00"}
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ trip_path(conn, :index)

      conn = get(conn, trip_path(conn, :index))

      assert html_response(conn, 200) =~ "Success! Your subscription has been created."

      assert html_response(conn, 200) =~ "Green Line"
      refute html_response(conn, 200) =~ "Green Line D"
      refute html_response(conn, 200) =~ "Green Line E"
    end

    test "green line single-route", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        destinations: ["place-coecl"],
        elevator: "true",
        end_time: %{"am_pm" => "AM", "hour" => "9", "minute" => "00"},
        escalator: "false",
        legs: ["Green"],
        modes: ["subway"],
        origins: ["place-symcl"],
        parking_area: "true",
        return_end_time: %{"am_pm" => "PM", "hour" => "6", "minute" => "00"},
        return_start_time: %{"am_pm" => "PM", "hour" => "5", "minute" => "00"},
        round_trip: "true",
        start_time: %{"am_pm" => "AM", "hour" => "8", "minute" => "00"}
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ trip_path(conn, :index)

      conn = get(conn, trip_path(conn, :index))

      assert html_response(conn, 200) =~ "Success! Your subscription has been created."

      refute html_response(conn, 200) =~ "Green Line C"
      assert html_response(conn, 200) =~ "Green Line E"
    end

    test "bus, single route", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        destinations: [""],
        elevator: "false",
        end_time: %{"am_pm" => "AM", "hour" => "9", "minute" => "00"},
        escalator: "false",
        legs: ["741 - 1"],
        modes: ["bus"],
        origins: [""],
        parking: "false",
        return_end_time: %{"am_pm" => "PM", "hour" => "6", "minute" => "00"},
        return_start_time: %{"am_pm" => "PM", "hour" => "5", "minute" => "00"},
        round_trip: "true",
        start_time: %{"am_pm" => "AM", "hour" => "8", "minute" => "00"},
        alternate_routes: "{}"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ trip_path(conn, :index)

      conn = get(conn, trip_path(conn, :index))

      assert html_response(conn, 200) =~
               "<span class=\"trip__card--route\">Silver Line SL1</span>"
    end

    test "bus, multi route", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        destinations: [""],
        elevator: "false",
        end_time: %{"am_pm" => "AM", "hour" => "9", "minute" => "00"},
        escalator: "false",
        legs: ["741 - 1"],
        modes: ["bus"],
        origins: [""],
        parking: "false",
        return_end_time: %{"am_pm" => "PM", "hour" => "6", "minute" => "00"},
        return_start_time: %{"am_pm" => "PM", "hour" => "5", "minute" => "00"},
        round_trip: "true",
        start_time: %{"am_pm" => "AM", "hour" => "8", "minute" => "00"},
        alternate_routes: "%7B%22741%20-%201%22:[%22747%20-%201~~Route%20CT2~~bus%22]%7D"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ trip_path(conn, :index)

      conn = get(conn, trip_path(conn, :index))

      assert html_response(conn, 200) =~
               "<span class=\"trip__card--route\">Silver Line SL1</span>"

      assert html_response(conn, 200) =~ "<span class=\"trip__card--route\">Route CT2</span>"
    end

    test "multi-leg, different directions", %{conn: conn, user: user} do
      trip = %{
        bike_storage: "false",
        destinations: ["place-nuniv", "place-pktrm"],
        elevator: "true",
        end_time: %{"am_pm" => "AM", "hour" => "9", "minute" => "0"},
        escalator: "false",
        legs: ["Green", "Red"],
        modes: ["subway", "subway"],
        origins: ["place-pktrm", "place-brdwy"],
        parking_area: "true",
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        return_end_time: %{"am_pm" => "PM", "hour" => "6", "minute" => "0"},
        return_start_time: %{"am_pm" => "PM", "hour" => "5", "minute" => "0"},
        round_trip: "true",
        start_time: %{"am_pm" => "AM", "hour" => "8", "minute" => "0"}
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 302) =~ trip_path(conn, :index)

      conn = get(conn, trip_path(conn, :index))

      html = html_response(conn, 200)
      assert html =~ "Success! Your subscription has been created."

      assert html =~ "Red Line"
      assert html =~ "Green Line E"
      assert html =~ "Round-trip"
      assert html =~ "Elevators, Parking"
      assert html =~ "Weekdays"
      assert html =~ "8:00A -  9:00A,  5:00P -  6:00P"
    end

    test "returns error message with no day selected", %{conn: conn, user: user} do
      trip = %{
        # Note that ':relevant_days' is missing. This simulates somebody not
        # selecting a day.
        bike_storage: "false",
        destinations: [""],
        elevator: "false",
        end_time: %{"am_pm" => "AM", "hour" => "9", "minute" => "00"},
        escalator: "false",
        legs: ["741 - 1"],
        modes: ["bus"],
        origins: [""],
        parking: "false",
        return_end_time: %{"am_pm" => "PM", "hour" => "6", "minute" => "00"},
        return_start_time: %{"am_pm" => "PM", "hour" => "5", "minute" => "00"},
        round_trip: "true",
        start_time: %{"am_pm" => "AM", "hour" => "8", "minute" => "00"},
        alternate_routes: "{}"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_path(conn, :create), %{trip: trip})

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
      |> post(trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Orange Line?"
    assert html_response(conn, 200) =~ "Do you transfer to another route or line?"
    refute html_response(conn, 200) =~ "Only stops on the same branch can be selected"
  end

  test "POST /trip/leg to create new trip leg (bus, multi-route)", %{conn: conn, user: user} do
    trip = %{
      alternate_routes:
        "%7B%22741%20-%201%22:%5B%22701%20-%201~~Route%20CT1~~bus%22,%22747%20-%201~~Route%20CT2~~bus%22%5D%7D",
      from_new_trip: "true",
      round_trip: "true",
      route: "741 - 1~~Silver Line SL1~~bus"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Which direction do you take Silver Line SL1 first?"

    assert html_response(conn, 200) =~
             "We’ll also apply this direction for Route CT1 and Route CT2."
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
      |> post(trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Green Line?"
    assert html_response(conn, 200) =~ "Do you transfer to another route, line, or branch?"
    assert html_response(conn, 200) =~ "Only stops on the same branch can be selected."

    assert html_response(conn, 200) =~
             "selected=\"selected\" value=\"place-pktrm\">Park Street</option>"
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
      saved_mode: "subway",
      alternate_routes: "{}"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(trip_trip_path(conn, :leg), %{trip: trip})

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
      |> post(trip_trip_path(conn, :leg), %{trip: trip})

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
      saved_mode: "subway",
      alternate_routes: "{}"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "true"
    assert html_response(conn, 200) =~ "Red"
    assert html_response(conn, 200) =~ "place-alfcl"
    assert html_response(conn, 200) =~ "place-pktrm"
  end

  test "POST /trip/leg to create first leg", %{conn: conn, user: user} do
    trip = %{
      from_new_trip: "true",
      round_trip: "true",
      route: "Red~~Red Line~~subway",
      alternate_routes: "{}"
    }

    conn =
      user
      |> guardian_login(conn)
      |> post(trip_trip_path(conn, :leg), %{trip: trip})

    assert html_response(conn, 200) =~ "Where do you get on the Red Line?"
    assert html_response(conn, 200) =~ "Do you transfer to another route, line, or branch?"
  end

  test "POST /trip/leg with errors", %{conn: conn, user: user} do
    conn =
      user
      |> guardian_login(conn)
      |> post(trip_trip_path(conn, :leg), %{trip: %{}})

    assert html_response(conn, 200) =~ "There was an error creating your trip. Please try again."
  end

  describe "POST /trip/times" do
    test "subway", %{conn: conn, user: user} do
      trip = %{
        destinations: ["place-pktrm"],
        legs: ["Red"],
        origins: ["place-alfcl"],
        round_trip: "true",
        modes: ["subway"],
        alternate_routes: "{}"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_trip_path(conn, :times), %{trip: trip})

      assert html_response(conn, 200) =~ "true"
      assert html_response(conn, 200) =~ "Red"
      assert html_response(conn, 200) =~ "place-alfcl"
      assert html_response(conn, 200) =~ "place-pktrm"
    end

    test "cr", %{conn: conn, user: user} do
      trip = %{
        destinations: ["place-DB-2265"],
        legs: ["CR-Fairmount"],
        origins: ["place-DB-0095"],
        round_trip: "true",
        modes: ["cr"],
        schedule_return: %{"CR-Fairmount" => ["17:45:00"]},
        schedule_start: %{"CR-Fairmount" => ["08:48:00"]},
        alternate_routes: "{}"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_trip_path(conn, :times), %{trip: trip})

      assert html_response(conn, 200) =~ "true"
      assert html_response(conn, 200) =~ "CR-Fairmount"
      assert html_response(conn, 200) =~ "place-DB-2265"
      assert html_response(conn, 200) =~ "place-DB-0095"
    end

    test "bus", %{conn: conn, user: user} do
      trip = %{
        destinations: [],
        legs: ["41 - 1"],
        origins: [],
        round_trip: "true",
        modes: ["bus"],
        alternate_routes: "{}"
      }

      conn =
        user
        |> guardian_login(conn)
        |> post(trip_trip_path(conn, :times), %{trip: trip})

      assert html_response(conn, 200) =~ "true"
    end
  end

  describe "PUT /trips/:trip_id" do
    test "cr", %{conn: conn, user: user} do
      trip = insert(:trip, %{user: user})

      insert(:subscription, %{
        trip_id: trip.id,
        type: :cr,
        origin: "place-DB-0095",
        destination: "place-DB-2265",
        route: "CR-Fairmount",
        user_id: user.id
      })

      data = %{
        "end_time" => %{"am_pm" => "AM", "hour" => "9", "minute" => "00"},
        "relevant_days" => ["monday", "tuesday", "wednesday", "thursday", "friday"],
        "return_end_time" => %{"am_pm" => "PM", "hour" => "6", "minute" => "00"},
        "return_start_time" => %{"am_pm" => "PM", "hour" => "5", "minute" => "00"},
        "schedule_return" => %{"CR-Fairmount" => ["17:45:00"]},
        "schedule_start" => %{"CR-Fairmount" => ["08:48:00"]},
        "start_time" => %{"am_pm" => "AM", "hour" => "8", "minute" => "00"}
      }

      conn =
        user
        |> guardian_login(conn)
        |> put("/trips/#{trip.id}", %{trip: data})

      assert html_response(conn, 302) =~ "redirected"
    end
  end

  test "PATCH /trips/:trip_id/pause", %{conn: conn, user: user} do
    trip = insert(:trip, %{user: user})

    insert(:subscription, %{
      trip_id: trip.id,
      type: :cr,
      origin: "place-DB-0095",
      destination: "place-DB-2265",
      route: "CR-Fairmount",
      user_id: user.id,
      paused: false
    })

    conn =
      user
      |> guardian_login(conn)
      |> patch("/trips/#{trip.id}/pause")

    assert html_response(conn, 302) =~ "redirected"
  end

  test "PATCH /trips/:trip_id/resume", %{conn: conn, user: user} do
    trip = insert(:trip, %{user: user})

    insert(:subscription, %{
      trip_id: trip.id,
      type: :cr,
      origin: "place-DB-0095",
      destination: "place-DB-2265",
      route: "CR-Fairmount",
      user_id: user.id,
      paused: true
    })

    conn =
      user
      |> guardian_login(conn)
      |> patch("/trips/#{trip.id}/resume")

    assert html_response(conn, 302) =~ "redirected"
  end
end
