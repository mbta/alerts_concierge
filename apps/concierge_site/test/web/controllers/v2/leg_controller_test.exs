defmodule ConciergeSite.V2.LegControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory

  test "GET /v2/trip/:trip_id/leg/new", %{conn: conn} do
    user = insert(:user)

    conn = user
    |> guardian_login(conn)
    |> get(v2_trip_leg_path(conn, :new, "trip_id"))

    conn = get(conn, "/v2/trip/:trip_id/leg/new")
    assert html_response(conn, 200) =~ "new leg"
  end

  test "POST /v2/trip/:trip_id/leg", %{conn: conn} do
    user = insert(:user)

    conn = user
    |> guardian_login(conn)
    |> post(v2_trip_leg_path(conn, :create, "trip_id"))

    conn = post(conn, "/v2/trip/:trip_id/leg", %{})
    assert html_response(conn, 200) =~ "new leg"
  end
end
