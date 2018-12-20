defmodule AlertProcessor.NotificationWindowFilterTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias AlertProcessor.Model.Alert
  alias AlertProcessor.NotificationWindowFilter
  import AlertProcessor.Factory

  describe "filter/3" do
    setup do
      alert = %Alert{
        id: "123",
        severity: :extreme
      }

      {:ok, alert: alert}
    end

    test "within notification window", %{alert: alert} do
      trip = build(:trip)

      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]

      subscription = build(:subscription, subscription_details)
      monday_at_7am = DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")

      result = NotificationWindowFilter.filter([subscription], alert, monday_at_7am)
      assert result == [subscription]
    end

    test "within notification window (start after end)", %{alert: alert} do
      trip = build(:trip)

      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[22:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]

      subscription = build(:subscription, subscription_details)
      monday_at_7am = DateTime.from_naive!(~N[2018-04-02 07:00:00], "Etc/UTC")

      result = NotificationWindowFilter.filter([subscription], alert, monday_at_7am)
      assert result == [subscription]
    end

    test "outside notification window (start after end)", %{alert: alert} do
      trip = build(:trip)

      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[22:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]

      subscription = build(:subscription, subscription_details)
      monday_at_10am = DateTime.from_naive!(~N[2018-04-02 10:00:00], "Etc/UTC")

      result = NotificationWindowFilter.filter([subscription], alert, monday_at_10am)
      assert result == []
    end

    test "outside notification window (day mismatch: sunday)", %{alert: alert} do
      trip = build(:trip)

      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]

      subscription = build(:subscription, subscription_details)
      sunday_at_7am = DateTime.from_naive!(~N[2018-04-01 07:00:00], "Etc/UTC")

      result = NotificationWindowFilter.filter([subscription], alert, sunday_at_7am)
      assert result == []
    end

    test "outside notification window (day mismatch: thursday)", %{alert: alert} do
      trip = build(:trip)

      subscription_details = [
        # Thursday is missing from `relevant_days`
        relevant_days: ~w(monday tuesday wednesday friday saturday sunday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]

      subscription = build(:subscription, subscription_details)
      thursday_at_7am = DateTime.from_naive!(~N[2018-04-05 07:00:00], "Etc/UTC")

      result = NotificationWindowFilter.filter([subscription], alert, thursday_at_7am)
      assert result == []
    end

    test "outside notification window (day match but time before window)", %{alert: alert} do
      trip = build(:trip)

      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]

      subscription = build(:subscription, subscription_details)
      monday_at_6am = DateTime.from_naive!(~N[2018-04-02 06:00:00], "Etc/UTC")

      result = NotificationWindowFilter.filter([subscription], alert, monday_at_6am)
      assert result == []
    end

    test "outside notification window (day match but time after window)", %{alert: alert} do
      trip = build(:trip)

      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]

      subscription = build(:subscription, subscription_details)
      monday_at_10am = DateTime.from_naive!(~N[2018-04-02 10:00:00], "Etc/UTC")

      result = NotificationWindowFilter.filter([subscription], alert, monday_at_10am)
      assert result == []
    end

    test "high priority alerts pass regardless of notification window", %{alert: alert} do
      high_priority_alert = %Alert{alert | severity: :high_priority}
      trip = build(:trip)

      # This would fail the pure notification window test
      subscription_details = [
        relevant_days: ~w(monday)a,
        start_time: ~T[08:00:00],
        end_time: ~T[09:00:00],
        trip: trip
      ]

      subscription = build(:subscription, subscription_details)
      monday_at_6am = DateTime.from_naive!(~N[2018-04-02 06:00:00], "Etc/UTC")

      result = NotificationWindowFilter.filter([subscription], high_priority_alert, monday_at_6am)
      assert result == [subscription]
    end
  end
end
