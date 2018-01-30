defmodule ConciergeSite.Integration.Matching do
  use ExUnit.Case
  import ConciergeSite.SubscriptionFactory
  import ConciergeSite.AlertFactory, only: [active_period: 3, severity_by_priority: 1]
  import ConciergeSite.NotificationFactory
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

  describe "bus subscription" do
    @subscription subscription(:bus, Map.merge(@base, %{"routes" => ["57A - 0"]}))

    test "all same: route, direction, time, activity and severity" do
      assert_notify alert(informed_entity: [bus_entity()]), @subscription
    end

    test "same route_type" do
      assert_notify alert(informed_entity: [bus_entity(route_id: nil, direction_id: nil)]), @subscription
    end

    test "same route_id and route_type" do
      assert_notify alert(informed_entity: [bus_entity(direction_id: nil)]), @subscription
    end

    test "similar: different time" do
      refute_notify alert(active_period: @alert_later_period, informed_entity: [bus_entity()]), @subscription
    end

    test "similar: different days (same time)" do
      refute_notify alert(active_period: @alert_weekend_period, informed_entity: [bus_entity()]), @subscription
    end

    test "similar: not severe enough" do
      refute_notify alert(severity: severity_by_priority("low"), informed_entity: [bus_entity()]), @subscription
    end

    test "similar: more severe" do
      assert_notify alert(severity: severity_by_priority("high"), informed_entity: [bus_entity()]), @subscription
    end

    test "similar: different activity" do
      refute_notify alert(informed_entity: [bus_entity(activities: ["NO_MATCH"])]), @subscription
    end

    test "similar: different route_type" do
      refute_notify alert(informed_entity: [bus_entity(route_type: 1)]), @subscription
    end

    test "similar: different route" do
      refute_notify alert(informed_entity: [bus_entity(route_id: "57B")]), @subscription
    end

    test "similar: different direction" do
      refute_notify alert(informed_entity: [bus_entity(direction_id: 1)]), @subscription
    end
  end

  describe "commuter rail subscription" do
    @subscription subscription(:commuter_rail, Map.merge(@base, %{
      "destination" => "place-north",
      "direction_id" => "1",
      "origin" => "Melrose Highlands",
      "route_id" => "CR-Haverhill",
      "trips" => ["288"]}))

    test "all same: trip, direction, time, activity and severity" do
      assert_notify alert(informed_entity: [cr_entity()]), @subscription
    end

    test "similar: different time" do
      refute_notify alert(active_period: @alert_later_period, informed_entity: [cr_entity()]), @subscription
    end

    test "similar: different days (same time)" do
      refute_notify alert(active_period: @alert_weekend_period, informed_entity: [cr_entity()]), @subscription
    end

    test "similar: not severe enough" do
      refute_notify alert(severity: severity_by_priority("low"), informed_entity: [cr_entity()]), @subscription
    end

    test "similar: more severe" do
      assert_notify alert(severity: severity_by_priority("high"), informed_entity: [cr_entity()]), @subscription
    end

    test "similar: different trip_id" do
      trip = %{"direction_id" => 1, "route_id" => "CR-Haverhill", "trip_id" => "CR-Weekday-Fall-17-227"}
      refute_notify alert(informed_entity: [cr_entity(trip: trip)]), @subscription
    end
  end

  describe "ferry subscription" do
    @subscription subscription(:ferry, Map.merge(@base, %{
      "destination" => "Boat-Long",
      "direction_id" => "1",
      "origin" => "Boat-Charlestown",
      "route_id" => "Boat-F4",
      "trips" => ["Boat-F4-Boat-Charlestown-08:00:00-weekday-1"]}))

    test "all same: trip, direction, time, activity and severity" do
      assert_notify alert(informed_entity: [ferry_entity()]), @subscription
    end

    test "similar: different time" do
      refute_notify alert(active_period: @alert_later_period, informed_entity: [ferry_entity()]), @subscription
    end

    test "similar: different days (same time)" do
      refute_notify alert(active_period: @alert_weekend_period, informed_entity: [ferry_entity()]), @subscription
    end

    test "similar: not severe enough" do
      refute_notify alert(severity: severity_by_priority("low"), informed_entity: [ferry_entity()]), @subscription
    end

    test "similar: more severe" do
      assert_notify alert(severity: severity_by_priority("high"), informed_entity: [ferry_entity()]), @subscription
    end

    test "similar: different activity" do
      refute_notify alert(informed_entity: [ferry_entity(activities: ["NO_MATCH"])]), @subscription
    end

    test "similar: different route_type" do
      refute_notify alert(informed_entity: [ferry_entity(route_type: 1)]), @subscription
    end

    test "similar: different route" do
      refute_notify alert(informed_entity: [ferry_entity(route_id: "Boat-F1")]), @subscription
    end

    test "similar: different trip_id" do
      trip = %{"direction_id" => 1, "route_id" => "Boat-F4", "trip_id" => "Boat-F4-1900-Long-Weekday"}
      refute_notify alert(informed_entity: [ferry_entity(trip: trip)]), @subscription
    end
  end

  describe "sent notification" do
    @subscription subscription(:subway, Map.merge(@base, %{"destination" => "place-brdwy",
                                                           "origin" => "place-harsq", "roaming" => "false"}))

    test "matches: no notification sent" do
      alert = alert(informed_entity: [subway_entity()])

      assert_notify alert, @subscription, []
    end

    test "does not match: notification already sent" do
      alert = alert(informed_entity: [subway_entity()])
      notification = notification(alert, [@subscription])

      refute_notify alert, @subscription, [notification]
    end

    test "matches: notification already sent but last push time changed" do
      alert = alert(informed_entity: [subway_entity()])
      notification = notification(:earlier, alert, [@subscription])

      [new_notification] = determine_recipients(alert, [@subscription], [notification])
      refute notification == new_notification
    end
  end

  describe "estimated duration" do
    @weekday_subscription subscription(:subway, Map.merge(@base, %{"destination" => "place-brdwy",
                                                           "origin" => "place-harsq", "roaming" => "false"}))

    @saturday_subscription subscription(:subway, Map.merge(@base, %{"destination" => "place-brdwy", "relevant_days" => ["saturday"],
                                                           "origin" => "place-harsq", "roaming" => "false"}))

    test "matches: estimated duration alert within 36 hours of created time" do
      [%{"start" => start_timestamp}] = @alert_weekend_period
      alert = alert(active_period: @alert_weekend_period, informed_entity: [subway_entity()], created_timestamp: start_timestamp, duration_certainty: "ESTIMATED")

      assert_notify alert, @weekday_subscription
    end

    test "does not match: estimated duration alert after 36 hours of created time" do
      [%{"start" => start_timestamp}] = @alert_weekend_period
      alert = alert(active_period: @alert_weekend_period, informed_entity: [subway_entity()], created_timestamp: start_timestamp, duration_certainty: "ESTIMATED")

      refute_notify alert, @saturday_subscription
    end
  end

  defp assert_notify(alert, subscription, notifications \\ []), do: assert notify?(alert, subscription, notifications)
  defp refute_notify(alert, subscription, notifications \\ []), do: refute notify?(alert, subscription, notifications)
  defp notify?(alert, subscription, notifications), do: determine_recipients(alert, [subscription], notifications) != []

  defp alert(overrides) do
    %{"severity" => severity_by_priority(@base["alert_priority_type"]), "active_period" => @alert_active_period}
    |> Map.merge(Map.new(overrides, fn {k, v} -> {Atom.to_string(k), v} end))
    |> ConciergeSite.AlertFactory.alert()
  end

  defp subway_entity(overrides \\ []) do
    %{"route_type" => 1, "route_id" => "Red", "direction_id" => 0, "stop_id" => "place-harsq", "activities" => ["BOARD"]}
    |> Map.merge(Map.new(overrides, fn {k, v} -> {Atom.to_string(k), v} end))
  end

  defp bus_entity(overrides \\ []) do
    %{"route_type" => 3, "route_id" => "57A", "direction_id" => 0, "activities" => ["BOARD"]}
    |> Map.merge(Map.new(overrides, fn {k, v} -> {Atom.to_string(k), v} end))
  end

  defp cr_entity(overrides \\ []) do
    %{
      "route_type" => 2,
      "route_id" => "CR-Haverhill",
      "activities" => ["BOARD"],
      "trip" => %{
        "direction_id" => 1,
        "route_id" => "CR-Haverhill",
        "trip_id" => "CR-Weekday-Fall-17-288"
      }}
    |> Map.merge(Map.new(overrides, fn {k, v} -> {Atom.to_string(k), v} end))
  end

  defp ferry_entity(overrides \\ []) do
    %{
      "route_type" => 4,
      "route_id" => "Boat-F4",
      "activities" => ["BOARD"],
      "trip" => %{
        "direction_id" => 1,
        "route_id" => "Boat-F4",
        "trip_id" => "Boat-F4-Boat-Charlestown-08:00:00-weekday-1"
      }}
    |> Map.merge(Map.new(overrides, fn {k, v} -> {Atom.to_string(k), v} end))
  end
end
