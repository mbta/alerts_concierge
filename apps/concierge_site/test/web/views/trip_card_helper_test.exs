defmodule ConciergeSite.TripCardHelperTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  alias ConciergeSite.TripCardHelper
  alias AlertProcessor.{Model.Trip, Model.Subscription}

  describe "render/2" do
    test "commuter", %{conn: conn} do
      trip = %Trip{
        id: Ecto.UUID.generate(),
        relevant_days: [:monday],
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        facility_types: [:elevator],
        roundtrip: false
      }

      # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
      trip_with_subscriptions = %{
        trip
        | subscriptions: [
            add_subscription_for_trip(trip, %{
              type: :subway,
              route: "Red",
              origin: "place-alfcl",
              destination: "place-portr",
              direction_id: 0,
              rank: 1
            }),
            add_subscription_for_trip(trip, %{
              type: :subway,
              route: "Orange",
              origin: "place-chncl",
              destination: "place-ogmnl",
              direction_id: 1,
              rank: 2
            }),
            add_subscription_for_trip(trip, %{
              type: :subway,
              route: "Green",
              origin: "place-lake",
              destination: "place-kencl",
              direction_id: 0,
              rank: 3
            }),
            add_subscription_for_trip(trip, %{
              type: :subway,
              route: "Green-B",
              origin: "place-lake",
              destination: "place-kencl",
              direction_id: 0,
              rank: 3
            }),
            add_subscription_for_trip(trip, %{
              type: :subway,
              route: "Blue",
              origin: "place-wondl",
              destination: "place-bomnl",
              direction_id: 0,
              rank: 4
            }),
            add_subscription_for_trip(trip, %{
              type: :subway,
              route: "Mattapan",
              origin: "place-asmnl",
              destination: "place-matt",
              direction_id: 0,
              rank: 5
            }),
            add_subscription_for_trip(trip, %{type: :bus, route: "57", direction_id: 0, rank: 6}),
            add_subscription_for_trip(trip, %{type: :bus, route: "741", direction_id: 0, rank: 6}),
            add_subscription_for_trip(trip, %{
              type: :cr,
              route: "CR-Haverhill",
              origin: "place-WR-0075",
              destination: "place-north",
              direction_id: 1,
              rank: 7
            }),
            add_subscription_for_trip(trip, %{
              type: :ferry,
              route: "Boat-F1",
              origin: "Boat-Long",
              destination: "Boat-Hingham",
              direction_id: 0,
              rank: 8
            }),
            add_subscription_for_trip(trip, %{
              type: :cr,
              route: "route-that-was-eliminated",
              origin: "place-north",
              destination: "stop-with-no-service-anymore",
              direction_id: 0,
              rank: 9
            })
          ]
      }

      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_with_subscriptions))
      assert html =~ "Red Line"
      assert html =~ "Orange Line"
      assert html =~ "Green Line"
      assert html =~ "Blue Line"
      assert html =~ "Mattapan Trolley"
      assert html =~ "Route 57"
      assert html =~ "Silver Line SL1"
      assert html =~ "Haverhill Line"
      assert html =~ "Hingham/Hull Ferry"
      assert html =~ "Unknown Route"
      assert html =~ "Unknown Stop"
      assert html =~ "One-way"
      refute html =~ "Round-trip"
      assert html =~ "Mon"
      assert html =~ "9:00A - 10:00A"
      assert html =~ "<div class=\"card trip__card"

      trip_all_weekdays = %{
        trip_with_subscriptions
        | relevant_days: [:monday, :tuesday, :wednesday, :thursday, :friday]
      }

      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_all_weekdays))
      assert html =~ "Weekdays"

      trip_all_weekends = %{trip_with_subscriptions | relevant_days: [:saturday, :sunday]}
      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_all_weekends))
      assert html =~ "Weekends"

      trip_all_days = %{
        trip_with_subscriptions
        | relevant_days: [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
      }

      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_all_days))
      assert html =~ "Every day"

      roundtrip = %{
        trip_with_subscriptions
        | roundtrip: true,
          return_start_time: ~T[13:00:00],
          return_end_time: ~T[14:00:00]
      }

      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, roundtrip))
      refute html =~ "One-way"
      assert html =~ "Round-trip"
      assert html =~ "9:00A - 10:00A,  1:00P -  2:00P"
    end

    test "accessiblity", %{conn: conn} do
      trip = %Trip{
        id: Ecto.UUID.generate(),
        relevant_days: [:monday, :tuesday],
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        trip_type: :accessibility,
        facility_types: [:elevator]
      }

      trip_with_subscriptions = %{
        trip
        | subscriptions: [
            add_subscription_for_trip(trip, %{origin: "place-chncl"}),
            add_subscription_for_trip(trip, %{route: "Orange"}),
            add_subscription_for_trip(trip, %{route: "Green"})
          ]
      }

      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_with_subscriptions))
      assert html =~ "Chinatown, Orange Line"
      assert html =~ "Mon, Tue"
      assert html =~ "Station features"
      assert html =~ "Elevators"
      assert html =~ "<div class=\"card trip__card"

      trip_escalator = %{trip_with_subscriptions | facility_types: [:escalator]}
      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_escalator))
      assert html =~ "Escalators"

      trip_both_facilities = %{trip_with_subscriptions | facility_types: [:elevator, :escalator]}
      html = Phoenix.HTML.safe_to_string(TripCardHelper.render(conn, trip_both_facilities))
      assert html =~ "Elevators, Escalators"

      html = Phoenix.HTML.safe_to_string(TripCardHelper.display(conn, trip_with_subscriptions))
      assert html =~ "<div class=\"card trip__card trip__card--display"
    end
  end

  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  defp add_subscription_for_trip(trip, params) do
    %Subscription{
      user_id: trip.user_id,
      trip_id: trip.id,
      relevant_days: trip.relevant_days,
      start_time: trip.start_time,
      end_time: trip.end_time,
      type: params[:type],
      route: params[:route],
      origin: params[:origin],
      destination: params[:destination],
      direction_id: params[:direction_id],
      rank: params[:rank]
    }
  end
end
