defmodule ConciergeSite.Integration.Matching do
  use ExUnit.Case, async: true
  import ConciergeSite.SubscriptionFactory
  import ConciergeSite.AlertFactory, only: [active_period: 3, severity_by_priority: 1]
  import ConciergeSite.NotificationFactory

  import AlertProcessor.SubscriptionFilterEngine,
    only: [determine_recipients: 3, determine_recipients: 4]

  import AlertProcessor.Factory

  @base %{
    "alert_priority_type" => "medium",
    "departure_end" => ~T[08:30:00],
    "departure_start" => ~T[08:00:00],
    "relevant_days" => ["weekday"],
    "return_start" => nil,
    "return_end" => nil
  }
  @alert_active_period [active_period(@base["departure_start"], @base["departure_end"], :tuesday)]
  @alert_weekend_period [active_period(@base["departure_start"], @base["departure_end"], :sunday)]
  @alert_later_period [active_period(~T[09:00:00], ~T[09:30:00], :monday)]

  describe "subway subscription" do
    subscription_details = [
      route_type: 1,
      direction_id: 0,
      route: "Red",
      origin: "place-harsq",
      destination: "place-brdwy",
      facility_types: ~w(elevator)a,
      start_time: ~T[08:00:00],
      end_time: ~T[08:30:00],
      relevant_days: ~w(monday tuesday wednesday thursday friday)a
    ]

    @subscription build(:subscription, subscription_details)
    subscription_roaming_details = [
      route_type: 1,
      direction_id: 1,
      route: "Red",
      origin: "place-harsq",
      destination: "place-brdwy",
      facility_types: ~w(elevator)a,
      start_time: ~T[08:00:00],
      end_time: ~T[08:30:00],
      relevant_days: ~w(monday tuesday wednesday thursday friday)a
    ]

    @subscription_roaming build(:subscription, subscription_roaming_details)

    test "all same: stop, direction, time, activity and severity" do
      assert_notify(alert(informed_entity: [entity(:subway)]), @subscription)
    end

    test "same route_type" do
      subway_entity =
        :subway
        |> entity()
        |> Map.delete("route_id")
        |> Map.delete("direction_id")
        |> Map.delete("stop_id")

      assert_notify(alert(informed_entity: [subway_entity]), @subscription)
    end

    test "same route_id and route_type" do
      subway_entity =
        :subway
        |> entity()
        |> Map.delete("direction_id")
        |> Map.delete("stop_id")

      assert_notify(alert(informed_entity: [subway_entity]), @subscription)
    end

    test "same route_id, route_type and direction" do
      assert_notify(
        alert(informed_entity: [Map.delete(entity(:subway), "stop_id")]),
        @subscription
      )
    end

    test "similar: different time" do
      refute_notify(
        alert(active_period: @alert_later_period, informed_entity: [entity(:subway)]),
        @subscription
      )
    end

    test "similar: different days (same time)" do
      refute_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [entity(:subway)]),
        @subscription
      )
    end

    test "similar: different activity" do
      refute_notify(
        alert(informed_entity: [entity(:subway, activities: ["NO_MATCH"])]),
        @subscription
      )
    end

    test "similar: different route_type" do
      refute_notify(alert(informed_entity: [entity(:subway, route_type: 2)]), @subscription)
    end

    test "similar: different route" do
      refute_notify(alert(informed_entity: [entity(:subway, route_id: "Blue")]), @subscription)
    end

    test "similar: different direction" do
      refute_notify(alert(informed_entity: [entity(:subway, direction_id: 1)]), @subscription)
    end

    test "similar: different stop -- not in between" do
      refute_notify(
        alert(informed_entity: [entity(:subway, stop_id: "place-asmnl")]),
        @subscription
      )
    end

    test "similar: different stop -- in between" do
      refute_notify(
        alert(informed_entity: [entity(:subway, stop_id: "place-cntsq")]),
        @subscription
      )
    end

    test "similar: different direction (roaming)" do
      assert_notify(
        alert(informed_entity: [entity(:subway, direction_id: 1)]),
        @subscription_roaming
      )
    end

    test "similar: different stop -- in between (roaming)" do
      informed_entity_details = %{
        "route_type" => 1,
        "direction_id" => 1,
        "route" => "Red",
        "stop_id" => "place-cntsq",
        "activities" => ["BOARD"]
      }

      refute_notify(alert(informed_entity: [informed_entity_details]), @subscription_roaming)
    end
  end

  describe "bus subscription" do
    subscription_details = [
      route_type: 3,
      direction_id: 0,
      route: "57A",
      # no origin for bus subcsriptions
      origin: nil,
      # no destinations for bus subscriptions
      destination: nil,
      facility_types: [],
      start_time: ~T[08:00:00],
      end_time: ~T[08:30:00],
      relevant_days: ~w(monday tuesday wednesday thursday friday)a
    ]

    @subscription build(:subscription, subscription_details)

    test "all same: route, direction, time, activity and severity" do
      assert_notify(alert(informed_entity: [entity(:bus)]), @subscription)
    end

    test "same route_type" do
      bus_entity =
        :bus
        |> entity()
        |> Map.delete("route_id")
        |> Map.delete("direction_id")

      assert_notify(alert(informed_entity: [bus_entity]), @subscription)
    end

    test "same route_id and route_type" do
      assert_notify(
        alert(informed_entity: [Map.delete(entity(:bus), "direction_id")]),
        @subscription
      )
    end

    test "similar: different time" do
      refute_notify(
        alert(active_period: @alert_later_period, informed_entity: [entity(:bus)]),
        @subscription
      )
    end

    test "similar: different days (same time)" do
      refute_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [entity(:bus)]),
        @subscription
      )
    end

    test "similar: different activity" do
      refute_notify(
        alert(informed_entity: [entity(:bus, activities: ["NO_MATCH"])]),
        @subscription
      )
    end

    test "similar: different route_type" do
      refute_notify(alert(informed_entity: [entity(:bus, route_type: 1)]), @subscription)
    end

    test "similar: different route" do
      refute_notify(alert(informed_entity: [entity(:bus, route_id: "57B")]), @subscription)
    end

    test "similar: different direction" do
      refute_notify(alert(informed_entity: [entity(:bus, direction_id: 1)]), @subscription)
    end
  end

  describe "commuter rail subscription" do
    subscription_details = [
      route_type: 2,
      direction_id: 1,
      route: "CR-Haverhill",
      origin: "Melrose Highlands",
      destination: "place-north",
      facility_types: [],
      start_time: ~T[08:00:00],
      end_time: ~T[08:30:00],
      relevant_days: ~w(monday tuesday wednesday thursday friday)a
    ]

    @subscription build(:subscription, subscription_details)

    test "all same: trip, direction, time, activity and severity" do
      assert_notify(alert(informed_entity: [entity(:commuter_rail)]), @subscription)
    end

    test "same route_type" do
      cr_entity =
        :commuter_rail
        |> entity()
        |> Map.delete("route_id")
        |> Map.delete("trip")

      assert_notify(alert(informed_entity: [cr_entity]), @subscription)
    end

    test "same route_id and route_type" do
      assert_notify(
        alert(informed_entity: [Map.delete(entity(:commuter_rail), "trip")]),
        @subscription
      )
    end

    test "similar: different time" do
      refute_notify(
        alert(active_period: @alert_later_period, informed_entity: [entity(:commuter_rail)]),
        @subscription
      )
    end

    test "similar: different days (same time)" do
      refute_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [entity(:commuter_rail)]),
        @subscription
      )
    end

    test "similar: different activity" do
      refute_notify(
        alert(informed_entity: [entity(:commuter_rail, activities: ["NO_MATCH"])]),
        @subscription
      )
    end

    test "similar: different route_type" do
      refute_notify(
        alert(informed_entity: [entity(:commuter_rail, route_type: 1)]),
        @subscription
      )
    end

    test "similar: different route" do
      refute_notify(
        alert(informed_entity: [entity(:commuter_rail, route_id: "CR-Fitchburg")]),
        @subscription
      )
    end

    test "similar: different direction" do
      trip = %{
        "direction_id" => 0,
        "route_id" => "CR-Haverhill",
        "trip_id" => "CR-Weekday-Fall-17-288"
      }

      refute_notify(
        alert(informed_entity: [entity(:commuter_rail, direction_id: 0, trip: trip)]),
        @subscription
      )
    end

    test "unknown effect detail does not effect matching or cause an error" do
      assert_notify(
        alert(effect_detail: "TEST", informed_entity: [entity(:commuter_rail)]),
        @subscription
      )
    end
  end

  describe "ferry subscription" do
    subscription_details = [
      route_type: 4,
      direction_id: 1,
      route: "Boat-F4",
      origin: "Boat-Charlestown",
      destination: "Boat-Long-South",
      facility_types: [],
      start_time: ~T[08:00:00],
      end_time: ~T[08:30:00],
      relevant_days: ~w(monday tuesday wednesday thursday friday)a
    ]

    @subscription build(:subscription, subscription_details)

    test "all same: trip, direction, time, activity and severity" do
      assert_notify(alert(informed_entity: [entity(:ferry)]), @subscription)
    end

    test "same route_type" do
      ferry_entity =
        :ferry
        |> entity()
        |> Map.delete("trip")
        |> Map.delete("route_id")

      assert_notify(alert(informed_entity: [ferry_entity]), @subscription)
    end

    test "same route_id and route_type" do
      assert_notify(alert(informed_entity: [Map.delete(entity(:ferry), "trip")]), @subscription)
    end

    test "similar: different time" do
      refute_notify(
        alert(active_period: @alert_later_period, informed_entity: [entity(:ferry)]),
        @subscription
      )
    end

    test "similar: different days (same time)" do
      refute_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [entity(:ferry)]),
        @subscription
      )
    end

    test "similar: different activity" do
      refute_notify(
        alert(informed_entity: [entity(:ferry, activities: ["NO_MATCH"])]),
        @subscription
      )
    end

    test "similar: different route_type" do
      refute_notify(alert(informed_entity: [entity(:ferry, route_type: 1)]), @subscription)
    end

    test "similar: different route" do
      refute_notify(alert(informed_entity: [entity(:ferry, route_id: "Boat-F1")]), @subscription)
    end

    test "similar: different direction" do
      refute_notify(
        alert(informed_entity: [entity(:ferry, direction_id: 0)]),
        @subscription
      )
    end
  end

  describe "accessibility subscriptions" do
    subscription_details = [
      route_type: 1,
      direction_id: 0,
      route: "Red",
      origin: "place-chncl",
      destination: "place-aqucl",
      # "elevator" triggers and "activities" match for "USING_WHEELCHAIR"
      facility_types: ~w(elevator)a,
      start_time: ~T[00:00:00],
      end_time: ~T[23:59:59],
      relevant_days: ~w(saturday sunday)a
    ]

    @subscription build(:subscription, subscription_details)

    test "all same: activity, route, stop, day" do
      informed_entity_details = %{
        "route_type" => 1,
        "direction_id" => nil,
        "route" => "Red",
        "stop" => "place-aqucl",
        "activities" => ["USING_WHEELCHAIR"]
      }

      assert_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [informed_entity_details]
        ),
        @subscription
      )
    end

    test "similar: activity, route, day" do
      assert_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:accessibility)]
        ),
        @subscription
      )
    end

    test "similar: activity, stop, day" do
      informed_entity_details = %{
        "route_type" => 1,
        "stop" => "place-chncl",
        "activities" => ["USING_WHEELCHAIR"]
      }

      assert_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [informed_entity_details]),
        @subscription
      )
    end

    test "similar: only activity" do
      informed_entity_details = %{
        "route_type" => 1,
        "activities" => ["USING_WHEELCHAIR"]
      }

      assert_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [informed_entity_details]),
        @subscription
      )
    end

    test "similar: different route" do
      refute_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:accessibility, route_id: "blue")]
        ),
        @subscription
      )
    end

    test "similar: different stop" do
      entity =
        :accessibility
        # Orange Line, Oak Grove
        |> entity(stop_id: "place-ogmnl")
        |> Map.delete("route_id")

      refute_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [entity]),
        @subscription
      )
    end

    test "all same: different day" do
      refute_notify(
        alert(
          active_period: @alert_active_period,
          informed_entity: [entity(:accessibility, stop_id: "place-chncl")]
        ),
        @subscription
      )
    end
  end

  describe "parking subscriptions" do
    @subscription subscription(:parking, %{
                    "relevant_days" => ["sunday", "sunday"],
                    "stops" => ["place-harsq", "place-ogmnl"]
                  })

    test "all same: activity, stop, day -- not possible to send because there are no parking facilities in data" do
      refute_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:parking)]
        ),
        @subscription
      )
    end

    test "similar: only activity" do
      entity =
        :parking
        |> entity()
        |> Map.delete("stop_id")

      refute_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [entity]),
        @subscription
      )
    end

    test "similar: different stop" do
      refute_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:parking, stop_id: "place-aqucl")]
        ),
        @subscription
      )
    end

    test "similar: different activity" do
      refute_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:parking, activities: ["BOARD"])]
        ),
        @subscription
      )
    end

    test "all same: different days" do
      refute_notify(
        alert(
          active_period: @alert_active_period,
          informed_entity: [entity(:parking)]
        ),
        @subscription
      )
    end
  end

  describe "bike storage subscriptions" do
    @subscription subscription(:bike, %{
                    "relevant_days" => ["sunday", "sunday"],
                    "stops" => ["place-harsq", "place-ogmnl"]
                  })

    test "all same: activity, stop, day -- not possible to send because there are no bike storage facilities in data" do
      refute_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:bike)]
        ),
        @subscription
      )
    end

    test "similar: only activity" do
      entity =
        :bike
        |> entity()
        |> Map.delete("stop_id")

      refute_notify(
        alert(active_period: @alert_weekend_period, informed_entity: [entity]),
        @subscription
      )
    end

    test "similar: different stop" do
      refute_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:bike, stop_id: "place-aqucl")]
        ),
        @subscription
      )
    end

    test "similar: different activity" do
      refute_notify(
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:bike, activities: ["BOARD"])]
        ),
        @subscription
      )
    end

    test "all same: different days" do
      refute_notify(
        alert(
          active_period: @alert_active_period,
          informed_entity: [entity(:bike)]
        ),
        @subscription
      )
    end
  end

  describe "sent notification" do
    subscription_details = [
      route_type: 1,
      direction_id: 0,
      route: "Red",
      origin: "place-harsq",
      destination: "place-brdwy",
      facility_types: [],
      start_time: ~T[08:00:00],
      end_time: ~T[08:30:00],
      relevant_days: ~w(monday tuesday wednesday saturday sunday)a
    ]

    @subscription build(:subscription, subscription_details)

    test "matches: no notification sent" do
      alert = alert(informed_entity: [entity(:subway)])

      assert_notify(alert, @subscription, [])
    end

    test "does not match: notification already sent" do
      alert = alert(informed_entity: [entity(:subway)])
      notification = notification(alert, [@subscription])

      refute_notify(alert, @subscription, [notification])
    end

    test "matches: notification already sent but last push time changed" do
      alert = alert(informed_entity: [entity(:subway)])
      notification = notification(:earlier, alert, [@subscription])
      monday_at_8am = DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")

      assert [_subscription] =
               determine_recipients(alert, [@subscription], [notification], monday_at_8am)
    end

    test "does not match: notification already sent but it has a closed_timestamp" do
      alert = alert(informed_entity: [entity(:subway)])
      notification = notification(:all_clear, alert, [@subscription])

      refute_notify(alert, @subscription, [notification])
    end
  end

  describe "estimated duration" do
    weekday_subscription_details = [
      route_type: 1,
      direction_id: 0,
      route: "Red",
      origin: "place-harsq",
      destination: "place-brdwy",
      facility_types: [],
      start_time: ~T[08:00:00],
      end_time: ~T[08:30:00],
      relevant_days: ~w(monday tuesday wednesday saturday sunday)a
    ]

    @weekday_subscription build(:subscription, weekday_subscription_details)

    @saturday_subscription subscription(
                             :subway,
                             Map.merge(@base, %{
                               "destination" => "place-brdwy",
                               "relevant_days" => ["saturday"],
                               "origin" => "place-harsq",
                               "roaming" => "false"
                             })
                           )

    test "matches: estimated duration alert within 36 hours of created time" do
      [%{"start" => start_timestamp}] = @alert_weekend_period

      alert =
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:subway)],
          created_timestamp: start_timestamp,
          duration_certainty: "ESTIMATED"
        )

      assert_notify(alert, @weekday_subscription)
    end

    test "does not match: estimated duration alert after 36 hours of created time" do
      [%{"start" => start_timestamp}] = @alert_weekend_period

      alert =
        alert(
          active_period: @alert_weekend_period,
          informed_entity: [entity(:subway)],
          created_timestamp: start_timestamp,
          duration_certainty: "ESTIMATED"
        )

      refute_notify(alert, @saturday_subscription)
    end
  end

  describe "overnight timeframes" do
    test "late night and early morning" do
      subscription_details = [
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-harsq",
        destination: "place-brdwy",
        facility_types: [],
        start_time: ~T[23:00:00],
        end_time: ~T[01:00:00],
        relevant_days: ~w(monday tuesday wednesday saturday sunday)a
      ]

      subscription = build(:subscription, subscription_details)

      late_alert =
        alert(
          informed_entity: [entity(:subway)],
          active_period: [active_period(~T[23:00:00], ~T[23:59:59], :monday)]
        )

      early_alert =
        alert(
          informed_entity: [entity(:subway)],
          active_period: [active_period(~T[00:00:00], ~T[01:00:00], :tuesday)]
        )

      mid_alert =
        alert(
          informed_entity: [entity(:subway)],
          active_period: [active_period(~T[02:00:00], ~T[03:00:00], :monday)]
        )

      assert_notify(late_alert, subscription)
      assert_notify(early_alert, subscription)
      refute_notify(mid_alert, subscription)
    end
  end

  describe "informed_entity's trip matching" do
    test "with origin scheduled time after subscription's start time" do
      subscription_details = [
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "Fairmount",
        destination: "Newmarket",
        facility_types: [],
        start_time: ~T[16:30:00],
        end_time: ~T[19:00:00],
        relevant_days: ~w(monday)a
      ]

      informed_entity = %{
        "route_type" => 2,
        "route_id" => "CR-Fairmount",
        "activities" => ["BOARD", "EXIT", "RIDE"],
        "trip" => %{
          "route_id" => "CR-Fairmount",
          # You'll have to take a look at the ExVCR cassette to make sense of
          # it but this trip leaves from Fairmount at 4:40PM. Since 4:40PM is
          # after the subscription's start time of 4:30PM, we should trigger a
          # notification.
          "trip_id" => "CR-Weekday-Spring-18-773",
          "direction_id" => 0
        }
      }

      subscription = build(:subscription, subscription_details)

      alert =
        alert(
          informed_entity: [informed_entity],
          active_period: [active_period(~T[16:00:00], ~T[18:00:00], :monday)]
        )

      assert_notify(alert, subscription)
    end

    test "with origin scheduled time before subscription's start time" do
      subscription_details = [
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "Fairmount",
        destination: "Newmarket",
        facility_types: [],
        start_time: ~T[17:00:00],
        end_time: ~T[19:00:00],
        relevant_days: ~w(monday)a
      ]

      informed_entity = %{
        "route_type" => 2,
        "route_id" => "CR-Fairmount",
        "activities" => ["BOARD", "EXIT", "RIDE"],
        "trip" => %{
          "route_id" => "CR-Fairmount",
          # You'll have to take a look at the ExVCR cassette to make sense of
          # it but this trip leaves from Fairmount at 4:40PM. Since 4:40PM is
          # before the subscription's start time of 5PM, we shouldn't trigger a
          # notification.
          "trip_id" => "CR-Weekday-Spring-18-773",
          "direction_id" => 0
        }
      }

      subscription = build(:subscription, subscription_details)

      alert =
        alert(
          informed_entity: [informed_entity],
          active_period: [active_period(~T[16:00:00], ~T[18:00:00], :monday)]
        )

      refute_notify(alert, subscription)
    end
  end

  describe "travel window" do
    test "with origin departure time within subscription's travel window" do
      subscription_details = [
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "Fairmount",
        destination: "Newmarket",
        facility_types: [],
        start_time: ~T[15:00:00],
        end_time: ~T[19:00:00],
        travel_start_time: ~T[16:30:00],
        travel_end_time: ~T[16:45:00],
        relevant_days: ~w(monday)a
      ]

      informed_entity = %{
        "route_type" => 2,
        "route_id" => "CR-Fairmount",
        "activities" => ["BOARD", "EXIT", "RIDE"],
        "trip" => %{
          "route_id" => "CR-Fairmount",
          # This trip leaves from Fairmount at 4:40PM
          "trip_id" => "CR-Weekday-Spring-18-773",
          "direction_id" => 0
        }
      }

      subscription = build(:subscription, subscription_details)

      alert =
        alert(
          informed_entity: [informed_entity],
          active_period: [active_period(~T[16:00:00], ~T[18:00:00], :monday)]
        )

      assert_notify(alert, subscription)
    end

    test "with origin departure time before subscription's travel window" do
      subscription_details = [
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "Fairmount",
        destination: "Newmarket",
        facility_types: [],
        start_time: ~T[15:00:00],
        end_time: ~T[19:00:00],
        travel_start_time: ~T[16:41:00],
        travel_end_time: ~T[16:45:00],
        relevant_days: ~w(monday)a
      ]

      informed_entity = %{
        "route_type" => 2,
        "route_id" => "CR-Fairmount",
        "activities" => ["BOARD", "EXIT", "RIDE"],
        "trip" => %{
          "route_id" => "CR-Fairmount",
          # This trip leaves from Fairmount at 4:40PM
          "trip_id" => "CR-Weekday-Spring-18-773",
          "direction_id" => 0
        }
      }

      subscription = build(:subscription, subscription_details)

      alert =
        alert(
          informed_entity: [informed_entity],
          active_period: [active_period(~T[16:00:00], ~T[18:00:00], :monday)]
        )

      refute_notify(alert, subscription)
    end

    test "with origin departure time after subscription's travel window" do
      subscription_details = [
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "Fairmount",
        destination: "Newmarket",
        facility_types: [],
        start_time: ~T[15:00:00],
        end_time: ~T[19:00:00],
        travel_start_time: ~T[16:30:00],
        travel_end_time: ~T[16:35:00],
        relevant_days: ~w(monday)a
      ]

      informed_entity = %{
        "route_type" => 2,
        "route_id" => "CR-Fairmount",
        "activities" => ["BOARD", "EXIT", "RIDE"],
        "trip" => %{
          "route_id" => "CR-Fairmount",
          # This trip leaves from Fairmount at 4:40PM
          "trip_id" => "CR-Weekday-Spring-18-773",
          "direction_id" => 0
        }
      }

      subscription = build(:subscription, subscription_details)

      alert =
        alert(
          informed_entity: [informed_entity],
          active_period: [active_period(~T[16:00:00], ~T[18:00:00], :monday)]
        )

      refute_notify(alert, subscription)
    end
  end

  defp assert_notify(alert, subscription, notifications \\ []),
    do: assert(notify?(alert, subscription, notifications))

  defp refute_notify(alert, subscription, notifications \\ []),
    do: refute(notify?(alert, subscription, notifications))

  defp notify?(alert, subscription, notifications),
    do: determine_recipients(alert, [subscription], notifications) != []

  defp alert(overrides) do
    %{
      "severity" => severity_by_priority(@base["alert_priority_type"]),
      "active_period" => @alert_active_period
    }
    |> override(overrides)
    |> ConciergeSite.AlertFactory.alert()
  end

  defp entity(type, overrides \\ [])

  defp entity(:subway, overrides) do
    params = %{
      "route_type" => 1,
      "route_id" => "Red",
      "direction_id" => 0,
      "stop_id" => "place-harsq",
      "activities" => ["BOARD"]
    }

    override(params, overrides)
  end

  defp entity(:bus, overrides) do
    params = %{
      "route_type" => 3,
      "route_id" => "57A",
      "direction_id" => 0,
      "activities" => ["BOARD"]
    }

    override(params, overrides)
  end

  defp entity(:commuter_rail, overrides) do
    params = %{
      "route_type" => 2,
      "route_id" => "CR-Haverhill",
      "activities" => ["BOARD"],
      "direction_id" => 1,
      "trip" => %{
        "route_id" => "CR-Haverhill",
        "trip_id" => "CR-Weekday-Fall-17-288"
      }
    }

    override(params, overrides)
  end

  defp entity(:ferry, overrides) do
    params = %{
      "route_type" => 4,
      "route_id" => "Boat-F4",
      "activities" => ["BOARD"],
      "direction_id" => 1,
      "trip" => %{
        "route_id" => "Boat-F4",
        "trip_id" => "Boat-F4-1415-Charlestown-Weekday"
      }
    }

    override(params, overrides)
  end

  defp entity(:accessibility, overrides) do
    params = %{
      "activities" => ["USING_WHEELCHAIR"],
      "route_id" => "Red",
      "route_type" => 1,
      # place-alfcl
      "facility_id" => "349"
    }

    override(params, overrides)
  end

  defp entity(:parking, overrides) do
    params = %{
      "activities" => ["PARK_CAR"],
      "stop_id" => "place-harsq",
      "route_id" => "Red",
      "route_type" => 1
    }

    override(params, overrides)
  end

  defp entity(:bike, overrides) do
    params = %{
      "activities" => ["STORE_BIKE"],
      "stop_id" => "place-harsq",
      "route_id" => "Red",
      "route_type" => 1
    }

    override(params, overrides)
  end

  defp override(params, overrides),
    do: Map.merge(params, Map.new(overrides, fn {k, v} -> {Atom.to_string(k), v} end))
end
