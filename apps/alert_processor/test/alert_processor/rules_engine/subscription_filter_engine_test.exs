defmodule AlertProcessor.SubscriptionFilterEngineTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  import AlertProcessor.DateHelper

  alias AlertProcessor.{
    Model.Alert,
    Model.InformedEntity,
    Model.Notification,
    Model.Subscription,
    SendingQueue,
    SubscriptionFilterEngine
  }

  setup_all do
    {:ok, _} = Application.ensure_all_started(:alert_processor)
    {:ok, start_time} = DateTime.from_naive(~N[2017-04-26 09:00:00], "Etc/UTC")
    {:ok, start_time2} = DateTime.from_naive(~N[2017-08-01 09:00:00], "Etc/UTC")

    alert = %Alert{
      active_period: [%{start: start_time, end: nil}, %{start: start_time2, end: nil}],
      effect_name: "Delay",
      header: "This is a test message",
      id: "1",
      informed_entities: [
        %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}
      ],
      severity: :minor,
      last_push_notification: start_time,
      service_effect: "test"
    }

    {:ok, alert: alert}
  end

  describe "determine_recipients/1" do
    test "the expected subscription matches", %{alert: alert} do
      email_match = "route1,route4|weekdays|low,high|10am-2pm@test.com"
      email_no_match = "route2,route3|weekdays,sunday|low,high|10am-2pm@test.com"
      user = insert(:user, phone_number: nil, email: email_match)
      user2 = insert(:user, phone_number: nil, email: email_no_match)

      :subscription
      |> build(
        route_type: 1,
        user: user,
        informed_entities: [
          %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}
        ]
      )
      |> weekday_subscription
      |> insert

      :subscription
      |> build(
        route_type: 4,
        user: user,
        informed_entities: [
          %InformedEntity{route_type: 4, activities: InformedEntity.default_entity_activities()}
        ]
      )
      |> weekday_subscription
      |> insert

      :subscription
      |> build(
        route_type: 3,
        user: user2,
        informed_entities: [
          %InformedEntity{route_type: 3, activities: InformedEntity.default_entity_activities()}
        ]
      )
      |> weekday_subscription
      |> insert

      :subscription
      |> build(
        route_type: 2,
        user: user2,
        informed_entities: [
          %InformedEntity{route_type: 2, activities: InformedEntity.default_entity_activities()}
        ]
      )
      |> weekday_subscription
      |> sunday_subscription
      |> insert

      result = SubscriptionFilterEngine.determine_recipients(alert)

      assert [%Subscription{user: user}] = result
      assert email_match == user.email
    end

    test "a Red Line alert for the morning is matched only in the morning, same for afternoon" do
      # morning times
      date_2017_01_18__09_00 = naive_to_local(~N[2017-01-18 14:00:00])
      date_2017_01_18__11_00 = naive_to_local(~N[2017-01-18 16:00:00])

      # evening times
      date_2017_01_18__16_00 = naive_to_local(~N[2017-01-18 21:00:00])
      date_2017_01_18__17_00 = naive_to_local(~N[2017-01-18 22:00:00])

      # late times
      date_2017_01_18__20_00 = naive_to_local(~N[2017-01-19 01:00:00])
      date_2017_01_18__21_00 = naive_to_local(~N[2017-01-19 02:00:00])

      informed_entities = [
        %InformedEntity{
          route_type: 1,
          route: "Red",
          activities: InformedEntity.default_entity_activities()
        }
      ]

      # alerts
      alert_morning = %Alert{
        active_period: [%{start: date_2017_01_18__09_00, end: date_2017_01_18__11_00}],
        effect_name: "Delay",
        header: "This is a test message",
        id: "1",
        informed_entities: informed_entities,
        severity: :minor,
        last_push_notification: date_2017_01_18__09_00
      }

      alert_evening = %{
        alert_morning
        | active_period: [%{start: date_2017_01_18__16_00, end: date_2017_01_18__17_00}],
          id: "2"
      }

      alert_late = %{
        alert_morning
        | active_period: [%{start: date_2017_01_18__20_00, end: date_2017_01_18__21_00}],
          id: "3"
      }

      user_morning =
        insert(:user, phone_number: nil, email: "redline|weekdays|low|morning@test.com")

      # Morning subscription
      :subscription
      |> build(
        route_type: 1,
        route: "Red",
        user: user_morning,
        start_time: ~T[08:00:00],
        end_time: ~T[10:00:00],
        informed_entities: informed_entities
      )
      |> weekday_subscription()
      |> insert

      user_evening =
        insert(:user, phone_number: nil, email: "redline|weekdays|low|evening@test.com")

      # Evening subscription
      :subscription
      |> build(
        route_type: 1,
        route: "Red",
        user: user_evening,
        start_time: ~T[16:00:00],
        end_time: ~T[17:00:00],
        informed_entities: informed_entities
      )
      |> weekday_subscription()
      |> insert

      result_morning = SubscriptionFilterEngine.determine_recipients(alert_morning)

      result_evening = SubscriptionFilterEngine.determine_recipients(alert_evening)

      result_late = SubscriptionFilterEngine.determine_recipients(alert_late)

      assert [%Subscription{user: user}] = result_morning
      assert user_morning.email == user.email
      assert [%Subscription{user: user}] = result_evening
      assert user_evening.email == user.email
      assert result_late == []
    end
  end

  describe "schedule_distinct_notifications/2" do
    test "two subscription matches for the same alert-user sends only one notification", %{
      alert: alert
    } do
      user = insert(:user, phone_number: nil)

      :subscription
      |> build(
        route_type: 1,
        user: user,
        informed_entities: [
          %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}
        ]
      )
      |> weekday_subscription
      |> insert

      :subscription
      |> build(
        route_type: 1,
        user: user,
        informed_entities: [
          %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}
        ]
      )
      |> weekday_subscription
      |> insert

      subscriptions = SubscriptionFilterEngine.determine_recipients(alert)
      result = SubscriptionFilterEngine.schedule_distinct_notifications(alert, subscriptions)

      assert {:ok, notifications} = result
      assert length(subscriptions) == 2
      assert length(notifications) == 1
    end
  end

  describe "schedule_all_notifications/1" do
    test "one matching subscription causes one scheduled notification", %{alert: alert} do
      user = insert(:user, phone_number: nil)

      :subscription
      |> build(
        route_type: 1,
        user: user,
        informed_entities: [
          %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}
        ]
      )
      |> weekday_subscription
      |> insert

      {:ok, beginning_queue_length} = SendingQueue.queue_length()
      assert SubscriptionFilterEngine.schedule_all_notifications([alert])
      {:ok, ending_queue_length} = SendingQueue.queue_length()

      assert ending_queue_length - beginning_queue_length == 1
      assert {:ok, %Notification{}} = SendingQueue.pop()
    end
  end

  test "we don't send to users with communication_mode set to none", %{alert: alert} do
    comm_user = insert(:user, phone_number: nil)
    no_comm_user = insert(:user, communication_mode: "none")

    :subscription
    |> build(
      route_type: 1,
      user: comm_user,
      informed_entities: [
        %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}
      ]
    )
    |> weekday_subscription
    |> insert

    :subscription
    |> build(
      route_type: 1,
      user: no_comm_user,
      informed_entities: [
        %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}
      ]
    )
    |> weekday_subscription
    |> insert

    {:ok, beginning_queue_length} = SendingQueue.queue_length()
    assert SubscriptionFilterEngine.schedule_all_notifications([alert])
    {:ok, ending_queue_length} = SendingQueue.queue_length()

    assert ending_queue_length - beginning_queue_length == 1
    assert {:ok, %Notification{}} = SendingQueue.pop()
  end
end
