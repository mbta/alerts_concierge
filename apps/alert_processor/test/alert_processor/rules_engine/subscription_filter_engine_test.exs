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
      informed_entities: [%{route_type: 1}],
      severity: :minor
    }
    {:ok, alert: alert}
  end

  test "process_alert/1 when message provided", %{alert: alert} do
    user = insert(:user, phone_number: nil)
    user2 = insert(:user, phone_number: nil)

    :subscription
    |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1}])
    |> weekday_subscription
    |> insert
    :subscription
    |> build(user: user, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 4}])
    |> weekday_subscription
    |> insert
    :subscription
    |> build(user: user2, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3}])
    |> weekday_subscription
    |> insert
    :subscription
    |> build(user: user2, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 2}])
    |> weekday_subscription
    |> sunday_subscription
    |> insert
    assert {:ok, [%Notification{email: email}]} = SubscriptionFilterEngine.process_alert(alert)
    assert email == user.email
  end
end
