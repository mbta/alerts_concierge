defmodule AlertProcessor.NotificationBuilderTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.{Model, NotificationBuilder}
  alias AlertProcessor.Model.{Notification, InformedEntity}
  alias AlertProcessor.Helpers.DateTimeHelper
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

    utc_time = %{
      now: now,
      thirty_minutes_from_now: thirty_minutes_from_now,
      two_days_ago: two_days_ago,
      one_day_ago: one_day_ago,
      one_hour_from_now: one_hour_from_now,
      one_day_from_now: one_day_from_now,
      two_days_from_now: two_days_from_now,
      three_days_from_now: three_days_from_now
    }

    est_time =
      for {key, val} <- utc_time, into: %{} do
        {key, DT.shift_zone!(val, "America/New_York")}
      end

    {:ok, est_time: est_time, now: now}
  end

  test "build notification struct", %{est_time: est_time, now: now} do
    user = insert(:user)
    sub = insert(:subscription, user: user)

    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: est_time.two_days_from_now, end: est_time.three_days_from_now}],
      last_push_notification: now
    }

    notification = NotificationBuilder.build_notification({user, [sub]}, alert, now)
    local_now = DateTimeHelper.datetime_to_local(now)

    subscription_start =
      DT.from_date_and_time_and_zone!({2018, 1, 11}, {10, 0, 0}, "America/New_York")

    expected_notification = %Notification{
      alert_id: "1",
      user: user,
      user_id: user.id,
      header: nil,
      service_effect: nil,
      description: nil,
      url: alert.url,
      phone_number: user.phone_number,
      email: user.email,
      status: :unsent,
      last_push_notification: alert.last_push_notification,
      alert: alert,
      notification_subscriptions: [
        %AlertProcessor.Model.NotificationSubscription{
          subscription_id: sub.id
        }
      ],
      closed_timestamp: alert.closed_timestamp,
      type: :initial,
      tracking_matched_time: local_now,
      tracking_optimal_time: subscription_start
    }

    assert expected_notification == notification
  end

  test "logs warning if it errors replacing text", %{now: now} do
    user = build(:user)
    subscription = build(:subscription, user: user)

    alert = %Alert{
      header: "Newburyport Train 180 (25:25 pm from Newburyport)",
      id: "115346",
      informed_entities: [%InformedEntity{route_type: 2}],
      last_push_notification: now
    }

    function = fn ->
      NotificationBuilder.build_notification({user, [subscription]}, alert, now)
    end

    expected_log =
      "Error replacing text: alert_id=\"115346\" " <>
        "error=%ArgumentError{message: \"cannot convert {25, 25, 0} to time, " <>
        "reason: :invalid_time\"}"

    assert ExUnit.CaptureLog.capture_log(function) =~ expected_log
  end

  test "converts tracking_optimal_time to current time if it's in the future", %{
    est_time: est_time,
    now: now
  } do
    user = insert(:user)
    subscription = insert(:subscription, user: user, start_time: ~T[09:00:00])

    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: est_time.now, end: est_time.three_days_from_now}],
      last_push_notification: est_time.thirty_minutes_from_now
    }

    notification = NotificationBuilder.build_notification({user, [subscription]}, alert, now)

    assert notification.tracking_optimal_time == DateTimeHelper.datetime_to_local(now)
  end
end
