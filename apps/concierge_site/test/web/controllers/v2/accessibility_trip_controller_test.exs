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

  describe "POST /v2/accessibility_trips" do
    test "success", %{conn: conn, user: user} do
      trip = %{
        relevant_days: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        stops: ["place-pktrm"],
        elevator: "true",
        escalator: "false",
        routes: ["Red"],
      }

      conn = user
      |> guardian_login(conn)
      |> post(v2_accessibility_trip_path(conn, :create), %{trip: trip})

      redir_path = "/v2/trips"
      assert html_response(conn, 302) =~ redir_path
      conn = get(recycle(conn), redir_path)
      assert html_response(conn, 200) =~  "Accessibility trip created"
    end

    test "failure", %{conn: conn, user: user} do
      trip = %{
        relevant_days: [],
        stops: [],
        elevator: "false",
        escalator: "false",
        routes: []
      }

      conn = user
      |> guardian_login(conn)
      |> post(v2_accessibility_trip_path(conn, :create), %{trip: trip})

      assert html_response(conn, 200) =~  "Please correct the error and re-submit."
    end
  end
end
