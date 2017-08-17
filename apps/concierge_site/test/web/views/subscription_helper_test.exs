defmodule ConciergeSite.SubscriptionHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.SubscriptionHelper
  alias AlertProcessor.Model.Subscription

  test "relevant_days/1 stringifies and capitalizes days and returns comma separated iolist" do
    sub = %Subscription{
      relevant_days: [:saturday, :sunday, :weekday]
    }
    assert SubscriptionHelper.relevant_days(sub) == ["Saturday", "s, ", "Sunday", "s, ", "Weekday", "s"]
  end

  test "selected_relevant_days/1 returns a list of days if params contain a true value at day's key" do
    params = %{"saturday" => "true", "sunday" => "false", "weekday" => "true"}

    assert SubscriptionHelper.selected_relevant_days(params) == [:saturday, :weekday]
  end

  test "selected_relevant_days/1 returns :weekday if params has no days" do
    params = %{"trip_type" => "roaming"}

    assert SubscriptionHelper.selected_relevant_days(params) == [:weekday]
  end

  test "joined_day_list/1 returns a comma separated string of days with weekend days capitalized" do
    params = %{
      "trip_type" => "round_trip",
      "saturday" => "true",
      "sunday" => "true",
      "weekday" => "true"
    }

    days = SubscriptionHelper.joined_day_list(params)

    assert days == "Saturday, Sunday, or weekday"
  end

  test "joined_day_list/1 pluralizes weekday when trip_type is one_way" do
    params = %{
      "trip_type" => "one_way",
      "saturday" => "true",
      "sunday" => "true",
      "weekday" => "true"
    }

    days = SubscriptionHelper.joined_day_list(params)

    assert days == "Saturday, Sunday, or weekdays"
  end
end
