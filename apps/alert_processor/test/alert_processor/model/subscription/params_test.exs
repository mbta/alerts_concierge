defmodule AlertProcessor.Model.Subscription.ParamsTest do
  use ExUnit.Case
  alias AlertProcessor.Model.{
    Subscription,
    Subscription.Params,
  }

  describe "create_subscriptions/1" do
    test "returns error for invalid json" do
      assert Params.create_subscriptions(%{}) == :error
    end
    test "returns a subscription for valid json" do
      valid_json1 =  %{
        "alert_priority_type" => "low",
        "departure_end" => ~T[09:15:00],
        "departure_start" => ~T[08:45:00],
        "destination" => nil,
        "direction" => 1,
        "origin" => nil,
        "relevant_days" => ["saturday"],
        # "return_end" => ~T[17:15:00],
        "return_end" => nil,
        # "return_start" => ~T[16:45:00],
        "return_start" => nil,
        "route" => "741"
      }
      valid_json2 = %{
        "alert_priority_type" => "low",
        "departure_end" => ~T[14:00:00],
        "departure_start" => ~T[12:00:00],
        "destination" => "Anderson/ Woburn",
        "direction" => 0,
        "direction_id" => "0",
        "origin" => "place-north",
        "relevant_days" => ["weekday"],
        # "return_end" => ~T[20:00:00],
        "return_end" => nil,
        # "return_start" => ~T[18:00:00],
        "return_start" => nil,
        "return_trips" => ["588", "590"],
        "route" => "CR-Lowell",
        "route_id" => "CR-Lowell",
        "trips" => ["123", "125"]
      }

      assert [%Subscription{relevant_days: [:saturday]}] = Params.create_subscriptions(valid_json1)
      assert [%Subscription{relevant_days: [:tuesday]}] = Params.create_subscriptions(valid_json2)
    end
    test "returns one subscription for return_start and return_end containing json"
  end

end