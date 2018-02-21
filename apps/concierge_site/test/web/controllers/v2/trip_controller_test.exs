defmodule ConciergeSite.V2.TripControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory

  setup do
    user = insert(:user)

    {:ok, user: user}
  end

  test "GET /v2/trip/:id/edit", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_path(conn, :edit, "id"))

    assert html_response(conn, 200) =~ "edit trip"
  end

  test "GET /v2/trip/new", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_path(conn, :new))

    assert html_response(conn, 200) =~ "new trip"
  end

  test "POST /v2/trip", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_path(conn, :create, %{}))

    assert html_response(conn, 200) =~ "new trip"
  end

  test "PATCH /v2/trip/:id", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> patch(v2_trip_path(conn, :update, "id", %{}))

    assert html_response(conn, 200) =~ "edit trip"
  end

  test "GET /v2/trip/:trip_id/times", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_trip_path(conn, :new_times, "id"))

    assert html_response(conn, 200) =~ "new trip times"
  end

  test "POST /v2/trip/:trip_id/times", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_trip_path(conn, :create_times, "id", %{}))

    assert html_response(conn, 200) =~ "new trip times"
  end

  test "GET /v2/trip/:trip_id/accessibility", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_trip_path(conn, :accessibility, "id"))

    assert html_response(conn, 200) =~ "accessibility"
  end
end
