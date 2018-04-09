defmodule ConciergeSite.TripCardHelperTest do
  @moduledoc false
  use ConciergeSite.ConnCase
  alias ConciergeSite.TripCardHelper
  alias AlertProcessor.{Model.Trip, Model.Subscription}

  describe "render/2" do
    test "commuter", %{conn: conn} do
      trip = %Trip{id: Ecto.UUID.generate, alert_priority_type: :low, relevant_days: [:monday], start_time: ~T[09:00:00],
                   end_time: ~T[10:00:00], roundtrip: false}
      trip_with_subscriptions = %{trip | subscriptions: [
        add_subscription_for_trip(trip, %{type: :subway, route: "Red", origin: "place-alfcl", destination: "place-portr",
                                          direction_id: 0, rank: 1}),
        add_subscription_for_trip(trip, %{type: :subway, route: "Orange", origin: "place-chncl", destination: "place-ogmnl",
                                          direction_id: 1, rank: 2}),
        add_subscription_for_trip(trip, %{type: :subway, route: "Green", origin: "place-lake", destination: "place-kencl",
                                          direction_id: 0, rank: 3}),
        add_subscription_for_trip(trip, %{type: :subway, route: "Blue", origin: "place-wondl", destination: "place-bomnl",
                                          direction_id: 0, rank: 4}),
        add_subscription_for_trip(trip, %{type: :subway, route: "Mattapan", origin: "place-asmnl", destination: "place-matt",
                                          direction_id: 0, rank: 5}),
        add_subscription_for_trip(trip, %{type: :bus, route: "57A", direction_id: 0, rank: 6}),
        add_subscription_for_trip(trip, %{type: :cr, route: "CR-Haverhill", origin: "Melrose Highlands",
                                          destination: "place-north", direction_id: 1, rank: 7}),
        add_subscription_for_trip(trip, %{type: :ferry, route: "Boat-F4", origin: "Boat-Long",
                                          destination: "Boat-Charlestown", direction_id: 0, rank: 8})]}

      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_with_subscriptions))
      assert html =~ "Red"
      assert html =~ "Orange"
      assert html =~ "Green"
      assert html =~ "Blue"
      assert html =~ "Mattapan"
      assert html =~ "57A"
      assert html =~ "CR-Haverhill"
      assert html =~ "Boat-F4"
      assert html =~ "One-way"
      refute html =~ "Round-trip"
      assert html =~ "Mondays"
      assert html =~ "9:00am - 10:00am"

      trip_all_weekdays = %{trip_with_subscriptions | relevant_days: [:monday, :tuesday, :wednesday, :thursday, :friday]}
      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_all_weekdays))
      assert html =~ "Weekdays"

      trip_all_weekends = %{trip_with_subscriptions | relevant_days: [:saturday, :sunday]}
      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_all_weekends))
      assert html =~ "Weekends"

      roundtrip = %{trip_with_subscriptions | roundtrip: true, return_start_time: ~T[13:00:00], return_end_time: ~T[14:00:00]}
      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, roundtrip))
      refute html =~ "One-way"
      assert html =~ "Round-trip"
      assert html =~ "9:00am - 10:00am /  1:00pm -  2:00pm"
    end

    test "accessiblity", %{conn: conn} do
      trip = %Trip{id: Ecto.UUID.generate, alert_priority_type: :low, relevant_days: [:monday], start_time: ~T[09:00:00],
                   end_time: ~T[10:00:00], trip_type: :accessibility, facility_types: [:elevator]}
      trip_with_subscriptions = %{trip | subscriptions: [
        add_subscription_for_trip(trip, %{origin: "place-chncl"}),
        add_subscription_for_trip(trip, %{route: "Orange"})]}

      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_with_subscriptions))
      assert html =~ "Mondays — Chinatown, Orange Line"
      assert html =~ "Station features"
      assert html =~ "Elevators"

      trip_escalator = %{trip_with_subscriptions | facility_types: [:escalator]}
      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_escalator))
      assert html =~ "Escalators"

      trip_both_facilities = %{trip_with_subscriptions | facility_types: [:elevator, :escalator]}
      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_both_facilities))
      assert html =~ "Elevators and escalators"
    end
  end

  defp add_subscription_for_trip(trip, params) do
    %Subscription{user_id: trip.user_id, trip_id: trip.id, alert_priority_type: trip.alert_priority_type,
                  relevant_days: trip.relevant_days, start_time: trip.start_time, end_time: trip.end_time,
                  type: params[:type], route: params[:route], origin: params[:origin],
                  destination: params[:destination], direction_id: params[:direction_id], rank: params[:rank]}
  end
end
