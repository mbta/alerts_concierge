defmodule AlertProcessor.AlertParserTest do
  use AlertProcessor.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Bamboo.Test, shared: :true
  import AlertProcessor.Factory
  alias AlertProcessor.{AlertCache, AlertParser, Model, Repo}
  alias Model.{InformedEntity, SavedAlert}

  setup_all do
    {:ok, _} = Application.ensure_all_started(:alert_processor)
    HTTPoison.start
    :ok
  end

  test "process_alerts/1" do
    user = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "16", activities: InformedEntity.default_entity_activities()}])
    |> weekday_subscription
    |> PaperTrail.insert
    use_cassette "old_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert [{:ok, _} | _t] = AlertParser.process_alerts
      assert length(Repo.all(SavedAlert)) > 0
    end
    use_cassette "new_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert [{:ok, _} | _t] = AlertParser.process_alerts
    end
  end

  test "process_alerts/1 sends to correct users via filter chain" do
    user1 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user1, alert_priority_type: :low, informed_entities: [
        %InformedEntity{route_type: 2, route: "CR-Needham", activities: InformedEntity.default_entity_activities()},
        %InformedEntity{route_type: 2, route: "CR-Needham", direction_id: 1, activities: InformedEntity.default_entity_activities()}
      ])
    |> weekday_subscription
    |> PaperTrail.insert
    user2 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user2, alert_priority_type: :high, informed_entities: [
        %InformedEntity{route_type: 2, route: "CR-Needham", activities: InformedEntity.default_entity_activities()},
        %InformedEntity{route_type: 2, route: "CR-Needham", direction_id: 1, activities: InformedEntity.default_entity_activities()}
      ])
    |> weekday_subscription
    |> PaperTrail.insert
    user3 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user3, alert_priority_type: :low, informed_entities: [
        %InformedEntity{route_type: 2, route: "CR-Lowell", activities: InformedEntity.default_entity_activities()},
        %InformedEntity{route_type: 2, route: "CR-Lowell", direction_id: 1, activities: InformedEntity.default_entity_activities()}
      ])
    |> weekday_subscription
    |> PaperTrail.insert
    user4 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user4, alert_priority_type: :low, informed_entities: [
        %InformedEntity{route_type: 2, route: "CR-Needham", activities: InformedEntity.default_entity_activities()},
        %InformedEntity{route_type: 2, route: "CR-Needham", direction_id: 1, activities: InformedEntity.default_entity_activities()}
      ])
    |> weekday_subscription
    |> PaperTrail.insert
    insert(:notification, alert_id: "114166", last_push_notification: ~N[2017-06-19 20:02:14], user: user4, email: user4.email, phone_number: user4.phone_number, status: "sent", send_after: ~N[2017-04-25 10:00:00])

    use_cassette "unruly_passenger_alert", custom: true, clear_mock: true, match_requests_on: [:query] do
      [{:ok, notifications} | _] = AlertParser.process_alerts
      [notification | []] = notifications
      assert notification.header == "Board Needham Line on opposite track due to unruly passenger"
      assert notification.service_effect == "Needham Line track change"
    end
  end

  test "process_alerts/1 parses alerts and replaces facility id with type" do
    user1 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user1, alert_priority_type: :low, informed_entities: [%InformedEntity{stop: "place-davis", facility_type: :escalator, activities: ["USING_ESCALATOR"]}])
    |> weekday_subscription
    |> PaperTrail.insert

    use_cassette "facilities_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      result = AlertParser.process_alerts
      [notification] = Enum.reduce(result, [], fn({:ok, x}, acc) -> acc ++ x end)
      assert notification.header == "Escalator 343 DAVIS SQUARE - Unpaid Lobby to Holland Street unavailable today"
    end
  end

  test "process_alerts/1 parses alerts adds routes to facility entities" do
    use_cassette "facilities_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      AlertParser.process_alerts
      facility_entities =
        AlertCache.get_alerts()
        |> Enum.flat_map(&(&1.informed_entities))
        |> Enum.reject(&(is_nil(&1.facility_type)))

      for entity <- facility_entities do
        refute is_nil(entity.route)
      end
    end
  end

  test "correctly parses and matches trips" do
    user = insert(:user)

    subscription_factory()
    |> Map.put(:informed_entities, [%InformedEntity{trip: "775", activities: InformedEntity.default_entity_activities()}])
    |> Map.merge(%{type: :commuter_rail, user: user, relevant_days: [:weekday], start_time: ~T[00:00:00], end_time: ~T[23:59:59]})
    |> insert()

    use_cassette "trip_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      result = AlertParser.process_alerts()
      [notification] = Enum.reduce(result, [], fn({:ok, x}, acc) -> acc ++ x end)
      assert notification.header == "Fairmount Line Train 775 (5:00 pm from South Station) cancelled today due to congestion"
      assert notification.email == user.email
    end
  end

  test "correctly parses entities without activities" do
    use_cassette "no_activities_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert [] = AlertParser.process_alerts()
    end
  end
end
