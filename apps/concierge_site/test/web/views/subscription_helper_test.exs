defmodule ConciergeSite.SubscriptionHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.SubscriptionHelper
  alias AlertProcessor.Model.Subscription

  test "relevant_days/1 stringifies and capitalizes days and returns comma separated iolist" do
    sub = %Subscription{
      relevant_days: [:saturday, :sunday, :weekday]
    }
    assert SubscriptionHelper.relevant_days(sub) == ["Saturday", "s, ", "Sunday", "s, ", "Weekday"]
  end
end
