defmodule MbtaServer.AlertProcessor.AlertParserTest do
  use MbtaServer.Web.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Bamboo.Test
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{AlertParser, Model.InformedEntity}

  setup_all do
    HTTPoison.start
  end

  test "process_alerts/1" do
    user = insert(:user, phone_number: nil)
    build(:subscription, user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "16"}])
    |> weekday_subscription
    |> insert
    use_cassette "old_alerts", custom: true do
      assert [{:ok, _} | _t] = AlertParser.process_alerts
    end
    use_cassette "new_alerts", custom: true do
      assert [{:ok, _} | _t] = AlertParser.process_alerts
    end
  end

  test "process_alerts/1 sends to correct users via filter chain" do
    user1 = insert(:user, phone_number: nil)
    build(:subscription, user: user1, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "19"}])
    |> weekday_subscription
    |> insert
    user2 = insert(:user, phone_number: nil)
    build(:subscription, user: user2, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 3, route: "19"}])
    |> weekday_subscription
    |> insert
    user3 = insert(:user, phone_number: nil)
    build(:subscription, user: user3, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "1"}])
    |> weekday_subscription
    |> insert
    user4 = insert(:user, phone_number: nil)
    build(:subscription, user: user4, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "19"}])
    |> weekday_subscription
    |> insert
    insert(:notification, alert_id: "177528", user: user4, email: user4.email, phone_number: user4.phone_number, status: "sent", send_after: ~N[2017-04-25 10:00:00])
    use_cassette "route_19_minor_delay", custom: true do
      assert [{:ok, email} | []] = AlertParser.process_alerts
      [{nil, to_address} | _] = email.to
      assert to_address == user1.email
    end
  end
end
