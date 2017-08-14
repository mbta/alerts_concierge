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
end
