defmodule AlertProcessor.NotificationBuilderTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Model, NotificationBuilder}
  alias Model.Alert
  alias Calendar.DateTime, as: DT

  setup_all do
    now = DT.from_date_and_time_and_zone!({2018, 1, 11}, {14, 10, 55}, "Etc/UTC")
    two_days_ago = DT.subtract!(now, 172_800)
    one_day_ago = DT.subtract!(now, 86_400)
    thirty_minutes_from_now = DT.add!(now, 1800)
    one_hour_from_now = DT.add!(now, 3600)
    one_day_from_now = DT.add!(now, 86_400)
    two_days_from_now = DT.add!(now, 172_800)
    three_days_from_now = DT.add!(now, 172_800)

    time = %{
      now: now,
      thirty_minutes_from_now: thirty_minutes_from_now,
      two_days_ago: two_days_ago,
      one_day_ago: one_day_ago,
      one_hour_from_now: one_hour_from_now,
      one_day_from_now: one_day_from_now,
      two_days_from_now: two_days_from_now,
      three_days_from_now: three_days_from_now
    }

    {:ok, time: time}
  end

  test "build notifications for each active period of an alert", %{time: time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.two_days_from_now, end: time.three_days_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications({user, [sub]}, alert, time.now)
    assert DT.same_time?(notification.send_after, time.one_day_from_now)
  end

  test "do not build expired notifications", %{time: time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.two_days_ago, end: time.one_day_ago}]
    }

    assert Enum.empty? NotificationBuilder.build_notifications({user, [sub]}, alert, time.now)
  end

  test "set send after to current time for immediate alerts", %{time: time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.thirty_minutes_from_now, end: time.one_day_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications({user, [sub]}, alert, time.now)
    assert DT.same_time?(notification.send_after, time.now)
  end

  test "set send after to 24 hours before start of active period", %{time: time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.two_days_from_now, end: time.three_days_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications({user, [sub]}, alert, time.now)
    assert DT.same_time?(notification.send_after, time.one_day_from_now)
  end

  test "do not send notification if send_time - active_period end is inside vacation period", %{time: time} do
    user = insert(:user, vacation_start: time.now, vacation_end: time.two_days_from_now)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.thirty_minutes_from_now, end: time.one_day_from_now}]
    }

    assert Enum.empty? NotificationBuilder.build_notifications({user, [sub]}, alert, time.now)
  end

  test "send notification at end of vacation period if active_period overlaps", %{time: time} do
    user = insert(:user, vacation_start: time.now, vacation_end: time.one_day_from_now)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.thirty_minutes_from_now, end: time.three_days_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications({user, [sub]}, alert, time.now)
    assert DT.same_time?(notification.send_after, time.one_day_from_now)
    assert %DateTime{time_zone: "Etc/UTC"} = notification.send_after
  end

  test "do not send notification if send_time -> active_period end is inside blackout period", %{time: time} do
    do_not_disturb_start =
      time.now
      |> DT.shift_zone!("America/New_York")
      |> DT.to_time()

    do_not_disturb_end =
      time.one_hour_from_now
      |> DT.shift_zone!("America/New_York")
      |> DT.to_time()

    user = insert(
      :user,
      do_not_disturb_start: do_not_disturb_start,
      do_not_disturb_end: do_not_disturb_end
    )

    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.now, end: time.thirty_minutes_from_now}]
    }

    assert Enum.empty?  NotificationBuilder.build_notifications({user, [sub]}, alert, time.now)
  end

  test "send notification at end of blackout period if active_period overlaps", %{time: time} do
    do_not_disturb_start =
      time.now
      |> DT.shift_zone!("America/New_York")
      |> DT.to_time()

    do_not_disturb_end =
      time.one_hour_from_now
      |> DT.shift_zone!("America/New_York")
      |> DT.to_time()

    user = insert(
      :user,
      do_not_disturb_start: do_not_disturb_start,
      do_not_disturb_end: do_not_disturb_end
    )

    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.now, end: time.one_day_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications({user, [sub]}, alert, time.now)
    assert DT.same_time?(notification.send_after, time.one_hour_from_now)
  end


  test """
  Schedule alert after DND of same day

  Example:
  It is currently 5am
  DND is set for 8pm - 8am
  The active period is < 24 hours, so the default time to send the alert is immediately
  In this case, the alert would then get scheduled for 8am
  """ do
    today_5am = DT.from_date_and_time_and_zone!({2018, 1, 8}, {5, 0, 0}, "America/New_York")
    tomorrow_5am = DT.add!(today_5am, 86_400)
    today_8am = DT.from_date_and_time_and_zone!({2018, 1, 8}, {8, 0, 0}, "America/New_York")
    user = insert(
      :user,
      do_not_disturb_start: ~T[20:00:00],
      do_not_disturb_end: ~T[08:00:00]
    )

    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{
        start: today_5am,
        end: tomorrow_5am
      }]
    }

    [notification] = NotificationBuilder.build_notifications({user, [sub]}, alert, today_5am)
    assert DT.same_time?(notification.send_after, today_8am)
    assert %DateTime{time_zone: "Etc/UTC"} = notification.send_after
  end

  test """
  Schedule alert after DND of next day

  Example:
  It is currently 10pm
  DND is set for 8pm - 8am
  The default time to send the alert immediately 10pm
  In this case, the alert would then get scheduled for 8am *tomorrow*
  """ do
    today_10pm = DT.from_date_and_time_and_zone!({2018, 1, 11}, {22, 0, 0}, "America/New_York")
    tomorrow_10pm = DT.add!(today_10pm, 86_400)
    tomorrow_8am = DT.from_date_and_time_and_zone!({2018, 1, 12}, {8, 0, 0}, "America/New_York")
    user = insert(
      :user,
      do_not_disturb_start: ~T[20:00:00],
      do_not_disturb_end: ~T[08:00:00]
    )

    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{
        start: tomorrow_10pm,
        end: DT.add!(tomorrow_10pm, 86_400)
      }]
    }

    [notification] = NotificationBuilder.build_notifications({user, [sub]}, alert, today_10pm)
    assert DT.same_time?(notification.send_after, tomorrow_8am)
    assert %DateTime{time_zone: "Etc/UTC"} = notification.send_after
  end

  test "handles estimated timeframes", %{time: time} do
    three_hours = 60 * 60 * 3
    thirty_six_hours = 60 * 60 * 36
    user = insert(:user)
    sub1 = :subscription |> insert(user: user, start_time: ~T[07:00:00], end_time: ~T[08:00:00]) |> weekday_subscription()
    sub2 = :subscription |> insert(user: user, start_time: ~T[09:00:00], end_time: ~T[10:00:00]) |> weekday_subscription()
    sub3 = :subscription |> insert(user: user, start_time: ~T[10:00:00], end_time: ~T[11:00:00]) |> saturday_subscription()
    sub4 = :subscription |> insert(user: user, start_time: ~T[22:00:00], end_time: ~T[23:00:00]) |> weekday_subscription()

    alert = %Alert{
      id: "1",
      header: "header",
      severity: :minor,
      active_period: [%{
        start: DT.add!(time.now, 60),
        end: DT.add!(time.now, thirty_six_hours)
      }],
      duration_certainty: {:estimated, three_hours},
      created_at: time.now
    }

    [s4_notification_2, s1_notification, s4_notification_1] = NotificationBuilder.build_notifications({user, [sub1, sub3, sub2, sub4]}, alert, time.now)

    sub1_id = sub1.id
    sub4_id = sub4.id

    assert %{notification_subscriptions: [%{subscription_id: ^sub4_id}]} = s4_notification_2
    assert %{notification_subscriptions: [%{subscription_id: ^sub1_id}]} = s1_notification
    assert %{notification_subscriptions: [%{subscription_id: ^sub4_id}]} = s4_notification_1

    assert DT.same_time?(DT.add!(time.now, (86_400 * 2) - 655 - (12 * 60 * 60)), s4_notification_2.send_after)
    assert DT.same_time?(DT.add!(time.now, 86_400 - 655 - (3 * 60 * 60)), s1_notification.send_after)
    assert DT.same_time?(DT.add!(time.now, 86_400 - 655 - (12 * 60 * 60)), s4_notification_1.send_after)
  end
end
