defmodule ConciergeSite.Subscriptions.SubscriptionParamsTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.SubscriptionParams

  describe "prepare_for_update_changeset" do
    test "it converts revelant days to a list of atoms" do
      params = %{
        "alert_priority_type" => "high",
        "departure_end" => "23:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }

      {:ok, update_params} = SubscriptionParams.prepare_for_update_changeset(params)

      assert update_params["relevant_days"] == [:saturday, :sunday, :weekday]
    end

    test "it converts departure_start and departure_end to start_time and end_time" do
      params = %{
        "alert_priority_type" => "high",
        "departure_end" => "23:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }

      {:ok, %{
        "start_time" => st,
        "end_time" => et
        }} = SubscriptionParams.prepare_for_update_changeset(params)

      assert DateTime.to_time(st) == ~T[03:00:00]
      assert DateTime.to_time(et) == ~T[03:15:00]
    end

    test "it converts alert_priority_type to an atom" do
      params = %{
        "alert_priority_type" => "high",
        "departure_end" => "23:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }

      {:ok, update_params} = SubscriptionParams.prepare_for_update_changeset(params)

      assert update_params["alert_priority_type"] == :high
    end

    test "it returns an error if start time is beyond end of service day" do
      params = %{
        "alert_priority_type" => "high",
        "departure_start" => "23:15:00",
        "departure_end" => "07:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }

      {:error, error_message} = SubscriptionParams.prepare_for_update_changeset(params)
      assert IO.iodata_to_binary(error_message) == "Please correct the following errors to proceed: Start time on departure trip cannot be same as or later than end time. End of service day is 03:00AM."
    end
  end

  describe "outside_service_time_range" do
    test "it returns true for start time and end time that falls outside of one service day" do
      assert SubscriptionParams.outside_service_time_range("00:00:00", "08:00:00")
    end

    test "it returns false for time range that is within one service day" do
      refute SubscriptionParams.outside_service_time_range("23:00:00", "01:00:00")
    end

    test "returns false for subscriptions starting or ending at 3am" do
      refute SubscriptionParams.outside_service_time_range("12:00:00", "03:00:00")
      refute SubscriptionParams.outside_service_time_range("03:00:00", "15:00:00")
    end

    test "returns true for equal start and end times" do
      assert SubscriptionParams.outside_service_time_range("03:00:00", "03:00:00")
      assert SubscriptionParams.outside_service_time_range("12:00:00", "12:00:00")
    end
  end
end
