defmodule AlertProcessor.SubscriptionFilterEngineTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  import AlertProcessor.Helpers.DateTimeHelper, only: [naive_to_local: 1]
  alias AlertProcessor.{Model.Alert, Model.InformedEntity, Model.Subscription, SubscriptionFilterEngine}

  setup_all do
    {:ok, start_time} = DateTime.from_naive(~N[2017-04-26 09:00:00], "Etc/UTC")
    {:ok, start_time2} = DateTime.from_naive(~N[2017-08-01 09:00:00], "Etc/UTC")
    alert = %Alert{
      active_period: [%{start: start_time, end: nil}, %{start: start_time2, end: nil}],
      effect_name: "Delay",
      header: "This is a test message",
      id: "1",
      informed_entities: [%InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}],
      severity: :minor,
      last_push_notification: start_time
    }
    {:ok, alert: alert}
  end

  describe "determine_recipients/3" do
    test "the expected subscription matches", %{alert: alert} do
      email_match = "route1,route4|weekdays|low,high|10am-2pm@test.com"
      email_no_match = "route2,route3|weekdays,sunday|low,high|10am-2pm@test.com"
      user = insert(:user, phone_number: nil, email: email_match)
      user2 = insert(:user, phone_number: nil, email: email_no_match)

      s1 = :subscription
      |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}])
      |> weekday_subscription
      |> insert
      s2 = :subscription
      |> build(user: user, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 4, activities: InformedEntity.default_entity_activities()}])
      |> weekday_subscription
      |> insert

      s3 = :subscription
      |> build(user: user2, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, activities: InformedEntity.default_entity_activities()}])
      |> weekday_subscription
      |> insert
      s4 = :subscription
      |> build(user: user2, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 2, activities: InformedEntity.default_entity_activities()}])
      |> weekday_subscription
      |> sunday_subscription
      |> insert

      result = SubscriptionFilterEngine.determine_recipients(alert, [s1, s2, s3, s4], [])

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

      informed_entities = [%InformedEntity{route_type: 1, route: "Red",
                                           activities: InformedEntity.default_entity_activities()}]

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

      alert_evening = struct(alert_morning, %{active_period: [%{start: date_2017_01_18__16_00,
                                                                end: date_2017_01_18__17_00}], id: "2"})

      alert_late = struct(alert_morning, %{active_period: [%{start: date_2017_01_18__20_00,
                                                             end: date_2017_01_18__21_00}], id: "3"})

      user_morning = insert(:user, phone_number: nil, email: "redline|weekdays|low|morning@test.com")
      subscription_morning = :subscription
      |> build(user: user_morning, alert_priority_type: :low, start_time: ~T[08:00:00], end_time: ~T[10:00:00],
               informed_entities: informed_entities)
      |> weekday_subscription()
      |> insert

      user_evening = insert(:user, phone_number: nil, email: "redline|weekdays|low|evening@test.com")
      evening_subscription = :subscription
      |> build(user: user_evening, alert_priority_type: :low, start_time: ~T[16:00:00], end_time: ~T[17:00:00],
               informed_entities: informed_entities)
      |> weekday_subscription()
      |> insert

      subscriptions = [subscription_morning, evening_subscription]

      result_morning = SubscriptionFilterEngine.determine_recipients(alert_morning, subscriptions, [])
      result_evening = SubscriptionFilterEngine.determine_recipients(alert_evening, subscriptions, [])
      result_late = SubscriptionFilterEngine.determine_recipients(alert_late, subscriptions, [])

      assert [%Subscription{user: user}] = result_morning
      assert user_morning.email == user.email
      assert [%Subscription{user: user}] = result_evening
      assert user_evening.email == user.email
      assert result_late == []
    end
  end

  describe "schedule_distinct_notifications/2" do
    test "two subscription matches for the same alert-user sends only one notification", %{alert: alert} do
      user = insert(:user, phone_number: nil)

      s1 = :subscription
      |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}])
      |> weekday_subscription
      |> insert
      s2 = :subscription
      |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}])
      |> weekday_subscription
      |> insert

      subscriptions = SubscriptionFilterEngine.determine_recipients(alert, [s1, s2], [])
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
      |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()}])
      |> weekday_subscription
      |> insert

      assert [{:ok, notifications}] = SubscriptionFilterEngine.schedule_all_notifications([alert])
      assert length(notifications) == 1
    end
  end
end
