defmodule ConciergeSite.Integration.Matching do
  use ExUnit.Case
  import ConciergeSite.{SubscriptionFactory, AlertFactory}
  alias AlertProcessor.{Model.Subscription, Model.InformedEntity, SubscriptionFilterEngine}

  @base_params %{"alert_priority_type" => "medium", "departure_end" => ~T[08:30:00],
                 "departure_start" => ~T[08:00:00], "relevant_days" => ["weekday"],
                 "return_start" => nil, "return_end" => nil}


  test "unified interface for creating subscriptions that matches front-end process" do
    subway_params = Map.merge(@base_params, %{"destination" => "place-chncl", "origin" => "place-ogmnl",
                                             "roaming" => "false"})
    assert %Subscription{informed_entities: [%InformedEntity{} | _]} = subscription(:subway, subway_params)

    bus_params = Map.merge(@base_params, %{"routes" => ["57A - 0"]})
    assert %Subscription{informed_entities: [%InformedEntity{} | _]} = subscription(:bus, bus_params)

    commuter_rail_params = Map.merge(@base_params, %{"destination" => "place-north", "direction_id" => "1",
                                                    "origin" => "Melrose Highlands", "route_id" => "CR-Haverhill",
                                                    "trips" => ["288"]})
    assert %Subscription{informed_entities: [%InformedEntity{} | _]} = subscription(:commuter_rail, commuter_rail_params)

    ferry_params = Map.merge(@base_params, %{"destination" => "Boat-Long", "direction_id" => "1",
                                            "origin" => "Boat-Charlestown", "route_id" => "Boat-F4",
                                            "trips" => ["Boat-F4-Boat-Charlestown-08:00:00-weekday-1"]})
    assert %Subscription{informed_entities: [%InformedEntity{} | _]} = subscription(:ferry, ferry_params)
  end

  test "subway subscriptions" do
    subway_params = Map.merge(@base_params, %{"destination" => "place-brdwy", "origin" => "place-harsq",
                                             "roaming" => "false"})
    subscription = subscription(:subway, subway_params)
    activities = nil
    trips = nil

    assert length(SubscriptionFilterEngine.determine_recipients(alert(:all, subscription, activities, trips), [subscription], [])) == 1
    assert length(SubscriptionFilterEngine.determine_recipients(alert(:not_route, subscription, activities, trips), [subscription], [])) == 0
  end
end
