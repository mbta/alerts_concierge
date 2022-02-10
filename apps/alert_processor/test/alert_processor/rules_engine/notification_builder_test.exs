defmodule AlertProcessor.NotificationBuilderTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.{DateHelper, Factory}
  alias AlertProcessor.{Model, NotificationBuilder}
  alias AlertProcessor.Model.{Notification, InformedEntity}
  alias Model.Alert

  test "build notification struct" do
    now = naive_to_local(~N[2018-01-11 14:10:55Z])
    one_hour_ago = DateTime.add(now, -3600)
    two_days_from_now = DateTime.add(now, 172_800)
    three_days_from_now = DateTime.add(now, 259_200)
    user = insert(:user)
    sub = insert(:subscription, user: user)

    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: two_days_from_now, end: three_days_from_now}],
      last_push_notification: one_hour_ago
    }

    notification = NotificationBuilder.build_notification({user, [sub]}, alert)

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
      type: :initial
    }

    assert expected_notification == notification
  end

  test "logs warning if it errors replacing text" do
    user = build(:user)
    subscription = build(:subscription, user: user)

    alert = %Alert{
      header: "Newburyport Train 180 (25:25 pm from Newburyport)",
      id: "115346",
      informed_entities: [%InformedEntity{route_type: 2}]
    }

    function = fn ->
      NotificationBuilder.build_notification({user, [subscription]}, alert)
    end

    expected_log =
      "Error replacing text: alert_id=\"115346\" " <>
        "error=%ArgumentError{message: \"cannot convert {25, 25, 0} to time, " <>
        "reason: :invalid_time\"}"

    assert ExUnit.CaptureLog.capture_log(function) =~ expected_log
  end
end
