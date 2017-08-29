defmodule AlertProcessor.SubscriptionFilterEngineTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Model.Alert, Model.InformedEntity, Model.Notification, SubscriptionFilterEngine}

  setup_all do
    {:ok, start_time} = DateTime.from_naive(~N[2017-04-26 09:00:00], "Etc/UTC")
    alert = %Alert{
      active_period: [%{start: start_time, end: nil}],
      effect_name: "Delay",
      header: "This is a test message",
      id: "1",
      informed_entities: [%InformedEntity{route_type: 1}],
      severity: :minor,
      last_push_notification: start_time
    }
    {:ok, alert: alert}
  end

  test "process_alert/1 when message provided", %{alert: alert} do
    user = insert(:user, phone_number: nil)
    user2 = insert(:user, phone_number: nil)

    s1 = :subscription
    |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1}])
    |> weekday_subscription
    |> insert
    s2 = :subscription
    |> build(user: user, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 4}])
    |> weekday_subscription
    |> insert
    s3 = :subscription
    |> build(user: user2, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3}])
    |> weekday_subscription
    |> insert
    s4 = :subscription
    |> build(user: user2, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 2}])
    |> weekday_subscription
    |> sunday_subscription
    |> insert

    result = SubscriptionFilterEngine.process_alert(alert, [s1, s2, s3, s4], [])

    assert {:ok, [%Notification{email: email}]} = result
    assert email == user.email
  end
end
