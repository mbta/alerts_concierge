defmodule ConciergeSite.TripViewTest do
  use ConciergeSite.ConnCase, async: true

  alias AlertProcessor.Model.Trip
  alias ConciergeSite.TripView

  describe "subscription_deleted_message/0" do
    test "Provides a user-friendly message we can alse use to determine if a trip was just deleted" do
      assert is_binary(TripView.subscription_deleted_message())
    end
  end

  describe "show_deleted_last_trip_survey?/2" do
    test "true if a subscription was just deleted and there are none left", %{conn: conn} do
      conn =
        conn
        |> get("/trips")
        |> put_flash(:info, TripView.subscription_deleted_message())

      trips = []

      assert TripView.show_deleted_last_trip_survey?(conn, trips)
    end

    test "false if a subscription wasn't just deleted", %{conn: conn} do
      conn =
        conn
        |> get("/trips")

      trips = []

      refute TripView.show_deleted_last_trip_survey?(conn, trips)
    end

    test "false if there are subscriptions left", %{conn: conn} do
      conn =
        conn
        |> get("/trips")
        |> put_flash(:info, TripView.subscription_deleted_message())

      trips = [%Trip{}]

      refute TripView.show_deleted_last_trip_survey?(conn, trips)
    end
  end
end
