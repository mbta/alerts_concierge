defmodule ConciergeSite.Integration.Matching do
  use ExUnit.Case
  import ConciergeSite.{SubscriptionFactory, AlertFactory}
  import AlertProcessor.SubscriptionFilterEngine, only: [determine_recipients: 3]

  @base %{"alert_priority_type" => "medium", "departure_end" => ~T[08:30:00], "departure_start" => ~T[08:00:00],
          "relevant_days" => ["weekday"], "return_start" => nil, "return_end" => nil}
  @alert_severity severity_by_priority(@base["alert_priority_type"])
  @alert_active_period [active_period(@base["departure_start"], @base["departure_end"], :monday)]
  @alert_weekend_period [active_period(@base["departure_start"], @base["departure_end"], :sunday)]
  @alert_later_period [active_period(~T[09:00:00], ~T[09:30:00], :monday)]

  describe "subway subscription" do
    @subscription subscription(:subway, Map.merge(@base, %{"destination" => "place-brdwy",
                                                           "origin" => "place-harsq", "roaming" => "false"}))
    @subscription_roaming subscription(:subway, Map.merge(@base, %{"destination" => "place-brdwy",
                                                                   "origin" => "place-harsq", "roaming" => "true"}))
    @alert_entity %{"route_type" => 1, "route_id" => "Red", "direction_id" => 0, "stop_id" => "place-harsq",
                   "activities" => ["BOARD"]}

    # Same
    test "all same: stop, direction, time, activity and severity" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [@alert_entity]})
      assert notify?(alert, @subscription)
    end

    test "same route_type" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "route_id" => nil, "direction_id" => nil,
                                                              "stop_id" => nil}]})
      assert notify?(alert, @subscription)
    end

    test "same route_id and route_type" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "direction_id" => nil,
                                                              "stop_id" => nil}]})
      assert notify?(alert, @subscription)
    end

    test "same route_id, route_type and direction" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "stop_id" => nil}]})
      assert notify?(alert, @subscription)
    end

    # Vary Time / Days
    test "similar: different time" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_later_period,
                      "informed_entity" => [@alert_entity]})
      refute notify?(alert, @subscription)
    end

    test "similar: different days (same time)" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_weekend_period,
                      "informed_entity" => [@alert_entity]})
      refute notify?(alert, @subscription)
    end

    # Vary Severity
    test "similar: not severe enough" do
      alert = alert(%{"severity" => severity_by_priority("low"), "active_period" => @alert_active_period,
                      "informed_entity" => [@alert_entity]})
      refute notify?(alert, @subscription)
    end

    test "similar: more severe" do
      alert = alert(%{"severity" => severity_by_priority("high"), "active_period" => @alert_active_period,
                      "informed_entity" => [@alert_entity]})
      assert notify?(alert, @subscription)
    end

    # Vary Activities
    test "similar: different activity" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "activities" => ["NO_MATCH"]}]})
      refute notify?(alert, @subscription)
    end

    # Vary Location
    test "similar: different route_type" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "route_type" => 2}]})
      refute notify?(alert, @subscription)
    end

    test "similar: different route" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "route_id" => "Blue"}]})
      refute notify?(alert, @subscription)
    end

    test "similar: different direction" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "direction_id" => 1}]})
      refute notify?(alert, @subscription)
    end

    test "similar: different stop -- not in between" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "stop_id" => "place-asmnl"}]})
      refute notify?(alert, @subscription)
    end

    test "similar: different stop -- in between" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "stop_id" => "place-cntsq"}]})
      refute notify?(alert, @subscription)
    end

    # Roaming
    test "similar: different direction (roaming)" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "direction_id" => 1}]})
      assert notify?(alert, @subscription_roaming)
    end

    test "similar: different stop -- in between (roaming)" do
      alert = alert(%{"severity" => @alert_severity, "active_period" => @alert_active_period,
                      "informed_entity" => [%{@alert_entity | "stop_id" => "place-cntsq"}]})
      assert notify?(alert, @subscription_roaming)
    end
  end

  defp notify?(alert, subscription), do: length(determine_recipients(alert, [subscription], [])) > 0
end
