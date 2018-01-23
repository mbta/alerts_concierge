defmodule ConciergeSite.Integration.Matching do
  use ExUnit.Case
  import ConciergeSite.SubscriptionFactory
  alias AlertProcessor.{Model.InformedEntity, Model.Subscription}

  test "unified interface for creating subscriptions that matches front-end process" do
    base_params = %{"alert_priority_type" => "medium", "departure_end" => ~T[08:30:00],
                    "departure_start" => ~T[08:00:00], "relevant_days" => ["weekday"]}

    subway_params = Map.merge(base_params, %{"destination" => "place-chncl", "origin" => "place-ogmnl",
                                             "roaming" => "false"})
    assert {:ok, [{%Subscription{}, [%InformedEntity{} | _]} | _]} = subscription(:subway, subway_params)

    bus_params = Map.merge(base_params, %{"routes" => ["57A - 0"]})
    assert {:ok, [{%Subscription{}, [%InformedEntity{} | _]} | _]} = subscription(:bus, bus_params)

    commuter_rail_params = Map.merge(base_params, %{"destination" => "place-north", "direction_id" => "1",
                                                    "origin" => "Melrose Highlands", "route_id" => "CR-Haverhill",
                                                    "trips" => ["288"]})
    assert {:ok, [{%Subscription{}, [%InformedEntity{} | _]} | _]} = subscription(:commuter_rail, commuter_rail_params)

    ferry_params = Map.merge(base_params, %{"destination" => "Boat-Long", "direction_id" => "1",
                                            "origin" => "Boat-Charlestown", "route_id" => "Boat-F4",
                                            "trips" => ["Boat-F4-Boat-Charlestown-08:00:00-weekday-1"]})
    assert {:ok, [{%Subscription{}, [%InformedEntity{} | _]} | _]} = subscription(:ferry, ferry_params)
  end

end
