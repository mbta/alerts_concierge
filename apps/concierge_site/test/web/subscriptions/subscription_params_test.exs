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

      update_params = SubscriptionParams.prepare_for_update_changeset(params)

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

      %{
        "start_time" => st,
        "end_time" => et
        } = SubscriptionParams.prepare_for_update_changeset(params)

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

      update_params = SubscriptionParams.prepare_for_update_changeset(params)

      assert update_params["alert_priority_type"] == :high
    end
  end
end
