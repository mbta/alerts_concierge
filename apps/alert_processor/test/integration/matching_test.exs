defmodule AlertProcessor.Integration.MatchingTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{AlertParser, ServiceInfoCache, SubscriptionFilterEngine}
  alias AlertProcessor.Model.{Alert, InformedEntity}

  setup_all do
    {:ok, _} = Application.ensure_all_started(:alert_processor)

    :ok
  end

  describe "subway subscription" do
    setup do
      insert(
        :subscription,
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-harsq",
        destination: "place-brdwy",
        facility_types: ~w(elevator)a,
        start_time: ~T[08:00:00],
        end_time: ~T[08:30:00],
        relevant_days: ~w(monday tuesday wednesday thursday friday)a
      )

      :ok
    end

    test "all same: stop, direction, time, activity and severity" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          route_type: 1
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_id and route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          route: "Red",
          route_type: 1
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_id, route_type and direction" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "similar: different time" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities, :later))
    end

    test "similar: different days (same time)" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["NO_MATCH"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 2,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different route" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Blue",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different direction" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different stop -- not in between" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-asmnl"
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different stop -- in between" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-cntsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different direction (roaming)" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different stop -- in between (roaming)" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route_type: 1,
          stop: "place-cntsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end
  end

  describe "bus subscription" do
    setup do
      insert(
        :subscription,
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
      )

      :ok
    end

    test "all same: route, direction, time, activity and severity" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "57A",
          route_type: 3
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          route_type: 3
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_id and route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          route: "57A",
          route_type: 3
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "similar: different time" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "57A",
          route_type: 3
        }
      ]

      refute_notify(alert(informed_entities, :later))
    end

    test "similar: different days (same time)" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "57A",
          route_type: 3
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["NO_MATCH"],
          direction_id: 0,
          route: "57A",
          route_type: 3
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "57A",
          route_type: 1
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different route" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "57B",
          route_type: 3
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different direction" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "57A",
          route_type: 3
        }
      ]

      refute_notify(alert(informed_entities))
    end
  end

  describe "commuter rail a subscription with early start_time" do
    setup do
      insert(
        :subscription,
        route_type: 2,
        direction_id: 1,
        route: "CR-Worcester",
        origin: "place-WML-0442",
        destination: "place-sstat",
        facility_types: [],
        start_time: ~T[01:00:00],
        end_time: ~T[19:00:00],
        travel_start_time: ~T[04:45:00],
        travel_end_time: ~T[18:05:00],
        relevant_days: ~w(monday tuesday wednesday thursday friday)a
      )

      :ok
    end

    test "matches when early start time and end time is after start time" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD", "EXIT", "RIDE"],
          direction_id: 1,
          route: "CR-Worcester",
          route_type: 2
        }
      ]

      assert_notify(alert(informed_entities))
    end
  end

  describe "commuter rail subscription" do
    setup do
      insert(
        :subscription,
        route_type: 2,
        direction_id: 1,
        route: "CR-Haverhill",
        origin: "place-WR-0075",
        destination: "place-north",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[08:30:00],
        relevant_days: ~w(monday tuesday wednesday thursday friday)a
      )

      :ok
    end

    test "all same: trip, direction, time, activity and severity" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "CR-Haverhill",
          route_type: 2
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route_type: 2
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_id and route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "CR-Haverhill",
          route_type: 2
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "similar: different time" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "CR-Haverhill",
          route_type: 2
        }
      ]

      refute_notify(alert(informed_entities, :later))
    end

    test "similar: different days (same time)" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "CR-Haverhill",
          route_type: 2
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["NO_MATCH"],
          direction_id: 1,
          route: "CR-Haverhill",
          route_type: 2
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "CR-Haverhill",
          route_type: 1
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different route" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "CR-Fitchburg",
          route_type: 2
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different direction" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "CR-Haverhill",
          route_type: 2
        }
      ]

      refute_notify(alert(informed_entities))
    end
  end

  describe "ferry subscription" do
    setup do
      insert(
        :subscription,
        route_type: 4,
        direction_id: 1,
        route: "Boat-F4",
        origin: "Boat-Charlestown",
        destination: "Boat-Long-South",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[08:30:00],
        relevant_days: ~w(monday tuesday wednesday thursday friday)a
      )

      :ok
    end

    test "all same: trip, direction, time, activity and severity" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "Boat-F4",
          route_type: 4
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          route_type: 4
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "same route_id and route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          route: "Boat-F4",
          route_type: 4
        }
      ]

      assert_notify(alert(informed_entities))
    end

    test "similar: different time" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "Boat-F4",
          route_type: 4
        }
      ]

      refute_notify(alert(informed_entities, :later))
    end

    test "similar: different days (same time)" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "Boat-F4",
          route_type: 4
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["NO_MATCH"],
          direction_id: 1,
          route: "Boat-F4",
          route_type: 4
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different route_type" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "Boat-F4",
          route_type: 1
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different route" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 1,
          route: "Boat-F1",
          route_type: 4
        }
      ]

      refute_notify(alert(informed_entities))
    end

    test "similar: different direction" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Boat-F4",
          route_type: 4
        }
      ]

      refute_notify(alert(informed_entities))
    end
  end

  describe "accessibility subscriptions" do
    setup do
      insert(
        :subscription,
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-chncl",
        destination: "place-aqucl",
        # "elevator" triggers and "activities" match for "USING_WHEELCHAIR"
        facility_types: ~w(elevator)a,
        start_time: ~T[08:00:00],
        end_time: ~T[23:59:59],
        relevant_days: ~w(saturday sunday)a
      )

      :ok
    end

    test "all same: activity, route, stop, day" do
      informed_entities = [
        %InformedEntity{
          activities: ["USING_WHEELCHAIR"],
          route_type: 1,
          route: "Red",
          stop: "place-aqucl"
        }
      ]

      assert_notify(alert(informed_entities, :sunday))
    end

    test "same: activity, route, day" do
      informed_entities = [
        %InformedEntity{
          activities: ["USING_WHEELCHAIR"],
          route_type: 1,
          route: "Red"
        }
      ]

      assert_notify(alert(informed_entities, :sunday))
    end

    test "same: activity, stop, day" do
      informed_entities = [
        %InformedEntity{
          activities: ["USING_WHEELCHAIR"],
          route_type: 1,
          stop: "place-aqucl"
        }
      ]

      assert_notify(alert(informed_entities, :sunday))
    end

    test "same: only activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["USING_WHEELCHAIR"],
          route_type: 1
        }
      ]

      assert_notify(alert(informed_entities, :sunday))
    end

    test "similar: different route" do
      informed_entities = [
        %InformedEntity{
          activities: ["USING_WHEELCHAIR"],
          route_type: 1,
          route: "Blue",
          stop: "place-aqucl"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different stop" do
      informed_entities = [
        %InformedEntity{
          activities: ["USING_WHEELCHAIR"],
          route_type: 1,
          route: "Red",
          stop: "place-ogmnl"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different day" do
      informed_entities = [
        %InformedEntity{
          activities: ["USING_WHEELCHAIR"],
          route_type: 1,
          route: "Red",
          stop: "place-aqucl"
        }
      ]

      refute_notify(alert(informed_entities))
    end
  end

  describe "parking subscriptions" do
    setup do
      insert(
        :subscription,
        type: :parking,
        start_time: ~T[00:00:00],
        end_time: ~T[23:59:59],
        relevant_days: ~w(sunday)a
      )

      :ok
    end

    test "all same: activity, stop, day -- not possible to send because there are no parking facilities in data" do
      informed_entities = [
        %InformedEntity{
          activities: ["PARK_CAR"],
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: only activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["PARK_CAR"],
          route: "Red",
          route_type: 1
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different stop" do
      informed_entities = [
        %InformedEntity{
          activities: ["PARK_CAR"],
          route: "Red",
          route_type: 1,
          stop: "place-aqucl"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different days" do
      informed_entities = [
        %InformedEntity{
          activities: ["PARK_CAR"],
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end
  end

  describe "bike storage subscriptions" do
    setup do
      insert(
        :subscription,
        type: :bike_storage,
        start_time: ~T[00:00:00],
        end_time: ~T[23:59:59],
        relevant_days: ~w(sunday)a
      )

      :ok
    end

    test "all same: activity, stop, day -- not possible to send because there are no bike storage facilities in data" do
      informed_entities = [
        %InformedEntity{
          activities: ["STORE_BIKE"],
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: only activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["STORE_BIKE"],
          route: "Red",
          route_type: 1
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different stop" do
      informed_entities = [
        %InformedEntity{
          activities: ["STORE_BIKE"],
          route: "Red",
          route_type: 1,
          stop: "place-aqucl"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different activity" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities, :sunday))
    end

    test "similar: different days" do
      informed_entities = [
        %InformedEntity{
          activities: ["STORE_BIKE"],
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities))
    end
  end

  describe "admin subscription" do
    test "subscribe to all alerts for a mode" do
      subscription =
        insert(
          :subscription,
          route_type: 2,
          is_admin: true
        )

      informed_entity = %InformedEntity{
        activities: ["BOARD"],
        direction_id: 1,
        route: "CR-Fitchburg",
        route_type: 2
      }

      alert = alert([informed_entity])
      now = Calendar.DateTime.now!("America/New_York")

      notified =
        alert
        |> SubscriptionFilterEngine.determine_recipients(now)
        |> Enum.map(& &1.id)

      assert notified == [subscription.id]
    end
  end

  describe "sent notification" do
    setup do
      user = insert(:user)

      subscription =
        insert(
          :subscription,
          user_id: user.id,
          route_type: 1,
          direction_id: 0,
          route: "Red",
          origin: "place-harsq",
          destination: "place-brdwy",
          facility_types: [],
          start_time: ~T[07:00:00],
          end_time: ~T[08:30:00],
          relevant_days: ~w(monday tuesday wednesday thursday friday saturday sunday)a
        )

      {:ok, subscription: subscription, user: user}
    end

    test "matches: no notification sent" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      assert_notify(
        alert(informed_entities),
        DateTime.from_naive!(~N[2018-01-01 08:10:00], "Etc/UTC")
      )
    end

    test "does not match: notification already sent", %{subscription: subscription, user: user} do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      alert = alert(informed_entities)

      notification =
        insert(:notification, %{
          alert_id: alert.id,
          user_id: user.id,
          status: :sent,
          last_push_notification: DateTime.from_naive!(~N[2018-01-01 08:01:00], "Etc/UTC"),
          inserted_at: DateTime.from_naive!(~N[2018-01-01 08:01:00], "Etc/UTC")
        })

      insert(:notification_subscription, %{
        subscription: subscription,
        notification: notification
      })

      refute_notify(alert, DateTime.from_naive!(~N[2018-01-01 08:10:00], "Etc/UTC"))
    end

    test "matches: notification already sent but last push time changed", %{
      subscription: subscription,
      user: user
    } do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      alert = alert(informed_entities)

      notification =
        insert(:notification, %{
          alert_id: alert.id,
          user_id: user.id,
          status: :sent,
          last_push_notification: DateTime.from_naive!(~N[2018-01-01 07:59:00], "Etc/UTC"),
          subscriptions: [subscription],
          inserted_at: DateTime.from_naive!(~N[2018-01-01 07:59:00], "Etc/UTC")
        })

      insert(:notification_subscription, %{
        subscription: subscription,
        notification: notification
      })

      assert_notify(alert, DateTime.from_naive!(~N[2018-01-01 08:10:00], "Etc/UTC"))
    end

    test "matches: notification already sent but it has a closed_timestamp - type is set to :all_clear",
         %{
           subscription: subscription,
           user: user
         } do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      alert = alert(informed_entities)

      notification =
        insert(:notification, %{
          alert_id: alert.id,
          user_id: user.id,
          status: :sent,
          last_push_notification: DateTime.from_naive!(~N[2018-01-01 07:59:00], "Etc/UTC"),
          subscriptions: [subscription],
          inserted_at: DateTime.from_naive!(~N[2018-01-01 07:59:00], "Etc/UTC"),
          closed_timestamp: DateTime.from_naive!(~N[2018-01-01 07:59:00], "Etc/UTC")
        })

      insert(:notification_subscription, %{
        subscription: subscription,
        notification: notification
      })

      assert_notify(alert, DateTime.from_naive!(~N[2018-01-01 08:10:00], "Etc/UTC"))
    end
  end

  describe "estimated duration" do
    test "matches: estimated duration alert within 36 hours of created time" do
      insert(
        :subscription,
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-harsq",
        destination: "place-brdwy",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[08:30:00],
        relevant_days: ~w(monday tuesday wednesday saturday sunday)a
      )

      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      assert_notify(alert(informed_entities, :sunday_extended))
    end

    test "does not match: estimated duration alert after 36 hours of created time" do
      insert(
        :subscription,
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-harsq",
        destination: "place-brdwy",
        facility_types: [],
        start_time: ~T[08:00:00],
        end_time: ~T[08:30:00],
        relevant_days: ~w(saturday)a
      )

      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities, :sunday_extended))
    end
  end

  describe "overnight timeframes" do
    setup do
      insert(
        :subscription,
        route_type: 1,
        direction_id: 0,
        route: "Red",
        origin: "place-harsq",
        destination: "place-brdwy",
        facility_types: [],
        start_time: ~T[23:00:00],
        end_time: ~T[01:00:00],
        relevant_days: ~w(monday tuesday wednesday saturday sunday)a
      )

      :ok
    end

    test "late night" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      assert_notify(alert(informed_entities, :late_night))
    end

    test "early morning" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      assert_notify(alert(informed_entities, :early_morning))
    end

    test "later early morning" do
      informed_entities = [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ]

      refute_notify(alert(informed_entities, :later_early_morning))
    end
  end

  # NOTE: The following tests use a set of specific trip IDs. At the time the tests are run, the
  # trip for the current day of the week must have schedules present in the API. All trips must
  # depart from Fairmount station outbound and the time must be specified here. These test trips
  # are active as of 2020-12-17.

  @test_trip_id (case Date.utc_today() |> Date.day_of_week() do
                   day when day in 1..5 -> "CR-Weekday-Winter-21-1907"
                   6 -> "CR-Saturday-Winter-21-2905"
                   7 -> "CR-Sunday-Winter-21-2905"
                 end)
  @test_trip_departs_fairmount_at ~T[10:13:00]

  describe "informed_entity's trip matching" do
    test "with origin scheduled time after subscription's start time" do
      insert(
        :subscription,
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "place-DB-2205",
        destination: "place-DB-0095",
        facility_types: [],
        start_time: Time.add(@test_trip_departs_fairmount_at, -20 * 60),
        end_time: Time.add(@test_trip_departs_fairmount_at, 60 * 60),
        relevant_days: ~w(monday)a
      )

      informed_entity_data = [
        %{
          "route_type" => 2,
          "route_id" => "CR-Fairmount",
          "activities" => ["BOARD", "EXIT", "RIDE"],
          "trip" => %{
            "route_id" => "CR-Fairmount",
            "trip_id" => @test_trip_id,
            "direction_id" => 0
          }
        }
      ]

      assert_notify(alert_from_parsed_data(informed_entity_data))
    end

    test "with origin scheduled time before subscription's start time" do
      insert(
        :subscription,
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "place-DB-2205",
        destination: "place-DB-0095",
        facility_types: [],
        start_time: Time.add(@test_trip_departs_fairmount_at, 20 * 60),
        end_time: Time.add(@test_trip_departs_fairmount_at, 60 * 60),
        relevant_days: ~w(monday)a
      )

      informed_entity_data = [
        %{
          "route_type" => 2,
          "route_id" => "CR-Fairmount",
          "activities" => ["BOARD", "EXIT", "RIDE"],
          "trip" => %{
            "route_id" => "CR-Fairmount",
            "trip_id" => @test_trip_id,
            "direction_id" => 0
          }
        }
      ]

      refute_notify(alert_from_parsed_data(informed_entity_data))
    end

    test "with a subscription origin outside of this trip's schedule" do
      # Dedham Corp Center to Foxboro, not served by the test trip
      insert(
        :subscription,
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "place-FB-0118",
        destination: "place-FS-0049",
        facility_types: [],
        start_time: ~T[06:00:00],
        end_time: ~T[09:00:00],
        relevant_days: ~w(monday)a
      )

      informed_entity_data = [
        %{
          "route_type" => 2,
          "route_id" => "CR-Fairmount",
          "activities" => ["BOARD", "EXIT", "RIDE"],
          "trip" => %{
            "route_id" => "CR-Fairmount",
            "trip_id" => @test_trip_id,
            "direction_id" => 0
          }
        }
      ]

      refute_notify(alert_from_parsed_data(informed_entity_data))
    end
  end

  describe "travel window" do
    test "with origin departure time within subscription's travel window" do
      insert(
        :subscription,
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "place-DB-2205",
        destination: "place-DB-0095",
        facility_types: [],
        start_time: Time.add(@test_trip_departs_fairmount_at, -60 * 60),
        end_time: Time.add(@test_trip_departs_fairmount_at, 120 * 60),
        travel_start_time: Time.add(@test_trip_departs_fairmount_at, -20 * 60),
        travel_end_time: Time.add(@test_trip_departs_fairmount_at, 60 * 60),
        relevant_days: ~w(monday)a
      )

      informed_entity_data = [
        %{
          "route_type" => 2,
          "route_id" => "CR-Fairmount",
          "activities" => ["BOARD", "EXIT", "RIDE"],
          "trip" => %{
            "route_id" => "CR-Fairmount",
            "trip_id" => @test_trip_id,
            "direction_id" => 0
          }
        }
      ]

      assert_notify(alert_from_parsed_data(informed_entity_data))
    end

    test "with origin departure time before subscription's travel window" do
      insert(
        :subscription,
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "place-DB-2205",
        destination: "place-DB-0095",
        facility_types: [],
        start_time: Time.add(@test_trip_departs_fairmount_at, -60 * 60),
        end_time: Time.add(@test_trip_departs_fairmount_at, 120 * 60),
        travel_start_time: Time.add(@test_trip_departs_fairmount_at, 20 * 60),
        travel_end_time: Time.add(@test_trip_departs_fairmount_at, 60 * 60),
        relevant_days: ~w(monday)a
      )

      informed_entity_data = [
        %{
          "route_type" => 2,
          "route_id" => "CR-Fairmount",
          "activities" => ["BOARD", "EXIT", "RIDE"],
          "trip" => %{
            "route_id" => "CR-Fairmount",
            "trip_id" => @test_trip_id,
            "direction_id" => 0
          }
        }
      ]

      refute_notify(alert_from_parsed_data(informed_entity_data))
    end

    test "with origin departure time after subscription's travel window" do
      insert(
        :subscription,
        route_type: 2,
        direction_id: 0,
        route: "CR-Fairmount",
        origin: "place-DB-2205",
        destination: "place-DB-0095",
        facility_types: [],
        start_time: Time.add(@test_trip_departs_fairmount_at, -60 * 60),
        end_time: Time.add(@test_trip_departs_fairmount_at, 120 * 60),
        travel_start_time: Time.add(@test_trip_departs_fairmount_at, -40 * 60),
        travel_end_time: Time.add(@test_trip_departs_fairmount_at, -20 * 60),
        relevant_days: ~w(monday)a
      )

      informed_entity_data = [
        %{
          "route_type" => 2,
          "route_id" => "CR-Fairmount",
          "activities" => ["BOARD", "EXIT", "RIDE"],
          "trip" => %{
            "route_id" => "CR-Fairmount",
            "trip_id" => @test_trip_id,
            "direction_id" => 0
          }
        }
      ]

      refute_notify(alert_from_parsed_data(informed_entity_data))
    end
  end

  defp assert_notify(alert, now \\ Calendar.DateTime.now!("America/New_York")),
    do: assert(notify?(alert, now))

  defp refute_notify(alert, now \\ Calendar.DateTime.now!("America/New_York")),
    do: refute(notify?(alert, now))

  defp notify?(alert, now), do: SubscriptionFilterEngine.determine_recipients(alert, now) != []

  defp alert(informed_entities, active_period_type \\ :default),
    do: %Alert{
      active_period: active_period(active_period_type),
      duration_certainty: :known,
      effect_name: "Service Change",
      header: "Header Text",
      id: "1",
      informed_entities: informed_entities,
      last_push_notification: DateTime.from_naive!(~N[2018-01-01 08:00:00], "Etc/UTC"),
      service_effect: "Service Effect",
      severity: :moderate
    }

  defp active_period(:default),
    do: [
      %{
        # Monday, 8:00 AM
        start: DateTime.from_naive!(~N[2018-01-01 08:00:00], "Etc/UTC"),
        # Monday, 8:30 AM
        end: DateTime.from_naive!(~N[2018-01-01 08:30:00], "Etc/UTC")
      }
    ]

  defp active_period(:later),
    do: [
      %{
        # Monday, 9:00 AM
        start: DateTime.from_naive!(~N[2018-01-01 09:00:00], "Etc/UTC"),
        # Monday, 9:30 AM
        end: DateTime.from_naive!(~N[2018-01-01 09:30:00], "Etc/UTC")
      }
    ]

  defp active_period(:sunday),
    do: [
      %{
        # Sunday, 8:00 AM
        start: DateTime.from_naive!(~N[2018-01-07 08:00:00], "Etc/UTC"),
        # Sunday, 8:30 AM
        end: DateTime.from_naive!(~N[2018-01-07 08:30:00], "Etc/UTC")
      }
    ]

  defp active_period(:sunday_extended),
    do: [
      %{
        # Sunday, 8:00 AM
        start: DateTime.from_naive!(~N[2018-01-07 08:00:00], "Etc/UTC"),
        # Monday, 8:00 PM (36 hours after start)
        end: DateTime.from_naive!(~N[2018-01-08 20:00:00], "Etc/UTC")
      }
    ]

  defp active_period(:late_night),
    do: [
      %{
        # Monday, 11:00 PM
        start: DateTime.from_naive!(~N[2018-01-01 23:00:00], "Etc/UTC"),
        # Monday, 11:59:59 PM
        end: DateTime.from_naive!(~N[2018-01-01 23:59:59], "Etc/UTC")
      }
    ]

  defp active_period(:early_morning),
    do: [
      %{
        # Tuesday, 12:00 AM
        start: DateTime.from_naive!(~N[2018-01-02 00:00:00], "Etc/UTC"),
        # Tuesday, 1:00 AM
        end: DateTime.from_naive!(~N[2018-01-02 01:00:00], "Etc/UTC")
      }
    ]

  defp active_period(:later_early_morning),
    do: [
      %{
        # Tuesday, 2:00 AM
        start: DateTime.from_naive!(~N[2018-01-02 02:00:00], "Etc/UTC"),
        # Tuesday, 3:00 AM
        end: DateTime.from_naive!(~N[2018-01-02 03:00:00], "Etc/UTC")
      }
    ]

  defp active_period(:late_afternoon),
    do: [
      %{
        # Monday, 4:00 PM
        start: DateTime.from_naive!(~N[2018-01-01 16:00:00], "Etc/UTC"),
        # Monday, 6:00 PM
        end: DateTime.from_naive!(~N[2018-01-01 18:00:00], "Etc/UTC")
      }
    ]

  defp alert_from_parsed_data(
         informed_entity_data,
         period_start \\ ~N[2018-01-01 05:00:00],
         period_end \\ ~N[2018-01-01 23:00:00]
       ) do
    # Monday, January 1, 2018 12:00:00 AM GMT-05:00 (EST)
    timestamp = 1_514_782_800

    {:ok, facilities_map} = ServiceInfoCache.get_facility_map()

    alert_data = %{
      "id" => "1",
      "created_timestamp" => timestamp,
      "duration_certainty" => :known,
      "effect_detail" => "SERVICE_CHANGE",
      "header_text" => [%{"translation" => %{"text" => "Header Text", "language" => "en"}}],
      "informed_entity" => informed_entity_data,
      "service_effect_text" => [
        %{"translation" => %{"text" => "Service Effect", "language" => "en"}}
      ],
      "severity" => 9,
      "last_push_notification_timestamp" => timestamp,
      "active_period" => [
        %{
          "start" => period_start |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
          "end" => period_end |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
        }
      ]
    }

    alert_data
    |> AlertParser.parse_alert(facilities_map, timestamp)
    |> List.first()
  end
end
