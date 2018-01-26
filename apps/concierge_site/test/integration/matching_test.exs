defmodule ConciergeSite.Integration.Matching do
  use ExUnit.Case
  import ConciergeSite.SubscriptionFactory
  import ConciergeSite.AlertFactory, only: [active_period: 3, severity_by_priority: 1]
  import AlertProcessor.SubscriptionFilterEngine, only: [determine_recipients: 3]

  @base %{"alert_priority_type" => "medium", "departure_end" => ~T[08:30:00], "departure_start" => ~T[08:00:00],
          "relevant_days" => ["weekday"], "return_start" => nil, "return_end" => nil}
  @alert_active_period [active_period(@base["departure_start"], @base["departure_end"], :monday)]
  @alert_weekend_period [active_period(@base["departure_start"], @base["departure_end"], :sunday)]
  @alert_later_period [active_period(~T[09:00:00], ~T[09:30:00], :monday)]

  describe "subway subscription" do
    @subscription subscription(:subway, Map.merge(@base, %{"destination" => "place-brdwy",
                                                           "origin" => "place-harsq", "roaming" => "false"}))
    @subscription_roaming subscription(:subway, Map.merge(@base, %{"destination" => "place-brdwy",
                                                                   "origin" => "place-harsq", "roaming" => "true"}))

    test "all same: stop, direction, time, activity and severity" do
      assert_notify alert(informed_entity: [subway_entity()]), @subscription
    end

    test "same route_type" do
      assert_notify alert(informed_entity: [subway_entity(route_id: nil, direction_id: nil, stop_id: nil)]), @subscription
    end

    test "same route_id and route_type" do
      assert_notify alert(informed_entity: [subway_entity(direction_id: nil, stop_id: nil)]), @subscription
    end

    test "same route_id, route_type and direction" do
      assert_notify alert(informed_entity: [subway_entity(stop_id: nil)]), @subscription
    end

    test "similar: different time" do
      refute_notify alert(active_period: @alert_later_period, informed_entity: [subway_entity()]), @subscription
    end

    test "similar: different days (same time)" do
      refute_notify alert(active_period: @alert_weekend_period, informed_entity: [subway_entity()]), @subscription
    end

    test "similar: not severe enough" do
      refute_notify alert(severity: severity_by_priority("low"), informed_entity: [subway_entity()]), @subscription
    end

    test "similar: more severe" do
      assert_notify alert(severity: severity_by_priority("high"), informed_entity: [subway_entity()]), @subscription
    end

    test "similar: different activity" do
      refute_notify alert(informed_entity: [subway_entity(activities: ["NO_MATCH"])]), @subscription
    end

    test "similar: different route_type" do
      refute_notify alert(informed_entity: [subway_entity(route_type: 2)]), @subscription
    end

    test "similar: different route" do
      refute_notify alert(informed_entity: [subway_entity(route_id: "Blue")]), @subscription
    end

    test "similar: different direction" do
      refute_notify alert(informed_entity: [subway_entity(direction_id: 1)]), @subscription
    end

    test "similar: different stop -- not in between" do
      refute_notify alert(informed_entity: [subway_entity(stop_id: "place-asmnl")]), @subscription
    end

    test "similar: different stop -- in between" do
      refute_notify alert(informed_entity: [subway_entity(stop_id: "place-cntsq")]), @subscription
    end

    test "similar: different direction (roaming)" do
      assert_notify alert(informed_entity: [subway_entity(direction_id: 1)]), @subscription_roaming
    end

    test "similar: different stop -- in between (roaming)" do
      assert_notify alert(informed_entity: [subway_entity(stop_id: "place-cntsq")]), @subscription_roaming
    end
  end

  defp assert_notify(alert, subscription), do: assert notify?(alert, subscription)
  defp refute_notify(alert, subscription), do: refute notify?(alert, subscription)
  defp notify?(alert, subscription), do: determine_recipients(alert, [subscription], []) != []

  defp alert(overrides) do
    %{"severity" => severity_by_priority(@base["alert_priority_type"]), "active_period" => @alert_active_period}
    |> Map.merge(Map.new(overrides, fn {k, v} -> {Atom.to_string(k), v} end))
    |> ConciergeSite.AlertFactory.alert()
  end

  defp subway_entity(overrides \\ []) do
    %{"route_type" => 1, "route_id" => "Red", "direction_id" => 0, "stop_id" => "place-harsq", "activities" => ["BOARD"]}
    |> Map.merge(Map.new(overrides, fn {k, v} -> {Atom.to_string(k), v} end))
  end
end
