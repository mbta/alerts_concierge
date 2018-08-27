defmodule ConciergeSite.TripReviewCardHelperTest do
  use ConciergeSite.ConnCase, async: true
  alias ConciergeSite.TripReviewCardHelper
  alias AlertProcessor.Model.{Subscription, Trip}

  describe "render/1" do
    test "generates html for a trip review card given a list of partial Subscriptions" do
      subscriptions = [
        %Subscription{
          type: :subway,
          route: "Red",
          origin: "place-alfcl",
          destination: "place-portr",
          direction_id: 0,
          rank: 1,
          return_trip: false
        },
        %Subscription{
          type: :subway,
          route: "Orange",
          origin: "place-chncl",
          destination: "place-ogmnl",
          direction_id: 1,
          rank: 2,
          return_trip: false
        },
        %Subscription{
          type: :subway,
          route: "Green",
          origin: "place-lake",
          destination: "place-kencl",
          direction_id: 0,
          rank: 3,
          return_trip: false
        }
      ]

      html = Phoenix.HTML.safe_to_string(TripReviewCardHelper.render(subscriptions))

      assert html =~ "<div class=\"trip-review"
    end

    test "generates html for a trip review card given a Trip" do
      trip = %Trip{
        id: Ecto.UUID.generate(),
        alert_priority_type: :low,
        relevant_days: [:monday],
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        roundtrip: false
      }

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
            add_subscription_for_trip(trip, %{type: :bus, route: "57A", direction_id: 0, rank: 6}),
            add_subscription_for_trip(trip, %{type: :bus, route: "741", direction_id: 0, rank: 6}),
            add_subscription_for_trip(trip, %{
              type: :cr,
              route: "CR-Haverhill",
              origin: "Melrose Highlands",
              destination: "place-north",
              direction_id: 1,
              rank: 7
            }),
            add_subscription_for_trip(trip, %{
              type: :ferry,
              route: "Boat-F4",
              origin: "Boat-Long",
              destination: "Boat-Charlestown",
              direction_id: 0,
              rank: 8
            })
          ]
      }

      html = Phoenix.HTML.safe_to_string(TripReviewCardHelper.render(trip_with_subscriptions))

      assert html =~ "<div class=\"trip-review"
    end
  end

  defp add_subscription_for_trip(trip, params) do
    %Subscription{
      user_id: trip.user_id,
      trip_id: trip.id,
      alert_priority_type: trip.alert_priority_type,
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
