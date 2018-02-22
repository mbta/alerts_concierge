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

    assert html_response(conn, 200) =~ "trip index"
  end

  test "GET /v2/trips/:id/edit", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_path(conn, :edit, "id"))

    assert html_response(conn, 200) =~ "edit trip"
  end

  test "PATCH /v2/trips/:id", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> patch(v2_trip_path(conn, :update, "id", %{}))

    assert html_response(conn, 200) =~ "edit trip"
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

    assert html_response(conn, 200) =~ "new trip"
  end

  test "POST /v2/trip", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_path(conn, :create, %{}))

    assert html_response(conn, 200) =~ "new trip"
  end

  test "GET /v2/trip/times", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_trip_path(conn, :new_times))

    assert html_response(conn, 200) =~ "new trip times"
  end

  test "POST /v2/trip/times", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_trip_path(conn, :create_times, %{}))

    assert html_response(conn, 200) =~ "new trip times"
  end

  test "GET /v2/trip/accessibility", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_trip_path(conn, :accessibility))

    assert html_response(conn, 200) =~ "accessibility"
  end
end
