defmodule AlertProcessor.Model.Subscription.SyncWithTripTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory

  alias AlertProcessor.Model.Subscription

  describe "perform/2" do
    test "updates departure subscription with trip attributes" do
      # a departure subscription has a `return_trip` value of false
      trip_details = %{
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[12:30:00]
      }

      trip = insert(:trip, trip_details)

      subscription_details = %{
        return_trip: false,
        relevant_days: [:tuesday],
        start_time: ~T[11:00:00],
        end_time: ~T[11:30:00],
        trip: trip
      }

      subscription = insert(:subscription, subscription_details)

      {:ok, %Subscription{}} = Subscription.sync_with_trip(subscription, trip)

      updated_subscription = Repo.get!(Subscription, subscription.id)

      assert updated_subscription.relevant_days == trip.relevant_days
      assert updated_subscription.start_time == trip.start_time
      assert updated_subscription.end_time == trip.end_time
    end

    test "updates return subscription with trip attributes" do
      # a return subscription has a `return_trip` value of true
      trip_details = %{
        relevant_days: [:monday],
        return_start_time: ~T[15:00:00],
        return_end_time: ~T[15:30:00]
      }

      trip = insert(:trip, trip_details)

      return_subscription_details = %{
        return_trip: true,
        relevant_days: [:tuesday],
        start_time: ~T[11:00:00],
        end_time: ~T[11:30:00],
        trip: trip
      }

      return_subscription = insert(:subscription, return_subscription_details)

      {:ok, %Subscription{}} = Subscription.sync_with_trip(return_subscription, trip)

      updated_return_subscription = Repo.get!(Subscription, return_subscription.id)

      assert updated_return_subscription.relevant_days == trip.relevant_days
      assert updated_return_subscription.start_time == trip.return_start_time
      assert updated_return_subscription.end_time == trip.return_end_time
    end
  end
end
