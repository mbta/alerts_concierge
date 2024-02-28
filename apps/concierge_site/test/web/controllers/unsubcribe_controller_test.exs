defmodule ConciergeSite.UnsubscribeControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Model.Subscription
  alias AlertProcessor.Repo

  describe "update/2" do
    test "unsubscribes user from al subscriptions", %{conn: conn} do
      trip_details = %{
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[12:30:00]
      }

      trip = insert(:trip, trip_details)

      subscription_details_1 = %{
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[12:30:00],
        origin: "some-origin",
        destination: "some-destination",
        trip: trip,
        paused: false,
        user_id: trip.user.id
      }

      subscription_details_2 = %{
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[12:30:00],
        origin: "some-other-origin",
        destination: "some-other-destination",
        trip: trip,
        paused: false,
        user_id: trip.user.id
      }

      subscription_1 = insert(:subscription, subscription_details_1)
      subscription_2 = insert(:subscription, subscription_details_2)

      post(
        conn,
        unsubscribe_path(conn, :update, trip.user.id)
      )

      updated_subscription_1 = Repo.get!(Subscription, subscription_1.id)
      updated_subscription_2 = Repo.get!(Subscription, subscription_2.id)

      for updated_subscription <- [updated_subscription_1, updated_subscription_2] do
        assert updated_subscription.paused == true
      end
    end
  end
end
