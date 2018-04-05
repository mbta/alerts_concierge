defmodule AlertProcessor.NotificationWindowFilterTest do
  use ExUnit.Case
  alias AlertProcessor.NotificationWindowFilter
  import AlertProcessor.Factory

  describe "filter/2" do
    test "within notification window" do
      trip_details = [
        alert_time_difference_in_minutes: 60
      ]
      trip = build(:trip, trip_details)
      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]
      subscription = build(:subscription, subscription_details)
      monday_at_7am = DateTime.from_naive!(~N[2018-04-02 07:00:00], "Etc/UTC")
      result = NotificationWindowFilter.filter([subscription], monday_at_7am)
      assert result == [subscription]
    end

    test "outside notification window (day mismatch: sunday)" do
      trip_details = [
        alert_time_difference_in_minutes: 60
      ]
      trip = build(:trip, trip_details)
      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]
      subscription = build(:subscription, subscription_details)
      sunday_at_7am = DateTime.from_naive!(~N[2018-04-01 07:00:00], "Etc/UTC")
      result = NotificationWindowFilter.filter([subscription], sunday_at_7am)
      assert result == []
    end

    test "outside notification window (day mismatch: thursday)" do
      trip_details = [
        alert_time_difference_in_minutes: 60
      ]
      trip = build(:trip, trip_details)
      subscription_details = [
        # Thursday is missing from `relevant_days`
        relevant_days: ~w(monday tuesday wednesday friday saturday sunday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]
      subscription = build(:subscription, subscription_details)
      thursday_at_7am = DateTime.from_naive!(~N[2018-04-05 07:00:00], "Etc/UTC")
      result = NotificationWindowFilter.filter([subscription], thursday_at_7am)
      assert result == []
    end

    test "outside notification window (day match but time before window)" do
      trip_details = [
        alert_time_difference_in_minutes: 60
      ]
      trip = build(:trip, trip_details)
      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]
      subscription = build(:subscription, subscription_details)
      monday_at_6am = DateTime.from_naive!(~N[2018-04-02 06:00:00], "Etc/UTC")
      result = NotificationWindowFilter.filter([subscription], monday_at_6am)
      assert result == []
    end

    test "outside notification window (day match but time after window)" do
      trip_details = [
        alert_time_difference_in_minutes: 60
      ]
      trip = build(:trip, trip_details)
      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]
      subscription = build(:subscription, subscription_details)
      monday_at_10am = DateTime.from_naive!(~N[2018-04-02 10:00:00], "Etc/UTC")
      result = NotificationWindowFilter.filter([subscription], monday_at_10am)
      assert result == []
    end
  end
end
