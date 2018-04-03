defmodule ConciergeSite.V2.AccessibilityTripControllerTest do
  use ConciergeSite.ConnCase

  setup do
    user = insert(:user)
    {:ok, user: user}
  end

  test "GET /v2/accessibility_trips/new", %{conn: conn, user: user} do
    conn = user
    |> guardian_login(conn)
    |> get(v2_accessibility_trip_path(conn, :new))

    assert html_response(conn, 200) =~ "accessibility"
  end

  test "POST /v2/accessibility_trips", %{conn: conn, user: user} do
    trip = %{type: "accessiblity"}

    conn = user
    |> guardian_login(conn)
    |> post(v2_accessibility_trip_path(conn, :create), %{trip: trip})

    redir_path = "/v2/trips"
    assert html_response(conn, 302) =~ redir_path
    conn = get(recycle(conn), redir_path)
    assert html_response(conn, 200) =~  "Accessibility trip created"
  end
end
