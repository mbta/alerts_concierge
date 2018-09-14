defmodule AlertProcessor.AlertParserTest do
  use AlertProcessor.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Bamboo.Test, shared: true
  import AlertProcessor.Factory
  alias AlertProcessor.{AlertParser, Model, Repo, AlertsClient, SendingQueue, ServiceInfoCache}
  alias Model.{InformedEntity, SavedAlert}
  alias Calendar.DateTime, as: DT

  setup_all do
    {:ok, _} = Application.ensure_all_started(:alert_processor)
    HTTPoison.start()
    :ok
  end

  test "process_alerts/1" do
    user = insert(:user, phone_number: nil)

    :subscription
    |> build(
      user: user,
      informed_entities: [
        %InformedEntity{
          route_type: 3,
          route: "16",
          activities: InformedEntity.default_entity_activities()
        }
      ]
    )
    |> weekday_subscription
    |> PaperTrail.insert()

    use_cassette "old_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      beginning_alerts = length(Repo.all(SavedAlert))
      assert AlertParser.process_alerts()
      ending_alerts = length(Repo.all(SavedAlert))
      assert ending_alerts - beginning_alerts == 2
    end

    use_cassette "new_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      beginning_alerts = length(Repo.all(SavedAlert))
      assert AlertParser.process_alerts()
      ending_alerts = length(Repo.all(SavedAlert))
      assert ending_alerts - beginning_alerts == 0
    end
  end

  test "process_alerts/1 sends to correct users via filter chain" do
    user1 = insert(:user, phone_number: nil)

    :subscription
    |> build(
      route_type: 2,
      route: "CR-Needham",
      direction_id: 1,
      user: user1
    )
    |> weekday_subscription
    |> PaperTrail.insert()

    user3 = insert(:user, phone_number: nil)

    :subscription
    |> build(
      route_type: 2,
      route: "CR-Lowell",
      direction_id: 1,
      user: user3
    )
    |> weekday_subscription
    |> PaperTrail.insert()

    user4 = insert(:user, phone_number: nil)

    :subscription
    |> build(
      route_type: 2,
      route: "CR-Needham",
      direction_id: 1,
      user: user4
    )
    |> weekday_subscription
    |> PaperTrail.insert()

    insert(
      :notification,
      alert_id: "114166",
      last_push_notification: ~N[2017-06-19 20:02:14],
      user: user4,
      email: user4.email,
      phone_number: user4.phone_number,
      status: "sent",
      send_after: ~N[2017-04-25 10:00:00]
    )

    use_cassette "unruly_passenger_alert",
      custom: true,
      clear_mock: true,
      match_requests_on: [:query] do
      assert AlertParser.process_alerts()
      {:ok, notification} = SendingQueue.pop()
      assert notification.header == "Board Needham Line on opposite track due to unruly passenger"
      assert notification.service_effect == "Needham Line track change"
    end
  end

  test "process_alerts/1 parses alerts and replaces facility id with type" do
    user1 = insert(:user, phone_number: nil)

    subscription_details = [
      route: "Red",
      origin: "place-davis",
      destination: "place-davis",
      facility_types: ~w(escalator)a,
      user: user1
    ]

    :subscription
    |> build(subscription_details)
    |> weekday_subscription
    |> PaperTrail.insert()

    use_cassette "facilities_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert AlertParser.process_alerts()

      {:ok, notification} = SendingQueue.pop()

      assert notification.header ==
               "Escalator 343 DAVIS SQUARE - Unpaid Lobby to Holland Street unavailable today"
    end
  end

  test "parse_alerts/1 parses alerts adds routes to facility entities" do
    use_cassette "facilities_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, alerts, feed_timestamp} = AlertsClient.get_alerts()
      {:ok, facility_map} = ServiceInfoCache.get_facility_map()

      facility_entities =
        {alerts, facility_map, feed_timestamp}
        |> AlertParser.parse_alerts()
        |> Enum.flat_map(& &1.informed_entities)
        |> Enum.reject(&is_nil(&1.facility_type))

      for entity <- facility_entities do
        refute is_nil(entity.route)
      end
    end
  end

  test "correctly parses bus stop alert to match bus route subscription" do
    user = insert(:user)

    subscription_details = [
      route_type: 3,
      route: "66",
      user: user
    ]

    :subscription
    |> build(subscription_details)
    |> bus_subscription()
    |> weekday_subscription()
    |> Map.put(:user, user)
    |> insert()

    use_cassette "bus_stop_alert", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert AlertParser.process_alerts()
      {:ok, notification} = SendingQueue.pop()
      assert notification.header == "Malcolm X Blvd @ King St (inbound) stop moving"
      assert notification.alert_id == "115718"
    end
  end

  test "correctly parses entities without activities" do
    use_cassette "no_activities_alerts",
      custom: true,
      clear_mock: true,
      match_requests_on: [:query] do
      beginning_alerts = length(Repo.all(SavedAlert))
      assert AlertParser.process_alerts()
      ending_alerts = length(Repo.all(SavedAlert))
      assert ending_alerts - beginning_alerts == 1
    end
  end

  test "correctly calculates active period" do
    use_cassette "known_alert", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, [alert], feed_timestamp} = AlertProcessor.AlertsClient.get_alerts()
      result = AlertParser.parse_alert(alert, %{}, feed_timestamp)

      assert %AlertProcessor.Model.Alert{
               active_period: [%{start: start_datetime, end: end_datetime}],
               created_at: created_at_datetime,
               duration_certainty: :known,
               effect_name: "Delay",
               header: "Red Line experiencing minor delays",
               id: "115513",
               informed_entities: _informed_entities,
               service_effect: "Minor Red Line delay",
               severity: :minor,
               closed_timestamp: nil
             } = result

      assert start_datetime == DT.from_erl!({{2017, 10, 10}, {13, 44, 54}}, "America/New_York")
      assert end_datetime == DT.from_erl!({{2017, 10, 10}, {18, 50, 34}}, "America/New_York")
      assert created_at_datetime == DT.from_erl!({{2017, 10, 10}, {17, 44, 59}}, "Etc/UTC")
    end
  end

  test "correctly parses estimated timeframe alert" do
    use_cassette "estimated_alert", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, [alert], feed_timestamp} = AlertProcessor.AlertsClient.get_alerts()
      result = AlertParser.parse_alert(alert, %{}, feed_timestamp)

      assert %AlertProcessor.Model.Alert{
               active_period: [%{start: start_datetime, end: end_datetime}],
               created_at: created_at_datetime,
               duration_certainty: {:estimated, 14400},
               effect_name: "Delay",
               header: "Red Line experiencing minor delays",
               id: "115513",
               informed_entities: _informed_entities,
               service_effect: "Minor Red Line delay",
               severity: :minor,
               closed_timestamp: nil
             } = result

      assert start_datetime == DT.from_erl!({{2017, 10, 10}, {13, 44, 54}}, "America/New_York")
      assert end_datetime == DT.from_erl!({{2017, 10, 12}, {1, 44, 59}}, "America/New_York")
      assert 1_507_661_434 == feed_timestamp

      assert 36 * 60 * 60 ==
               DateTime.to_unix(end_datetime) - DateTime.to_unix(created_at_datetime)
    end
  end

  test "rounds estimated duration to nearest 15 min to handle timestamp drift" do
    use_cassette "estimated_alert_drifted",
      custom: true,
      clear_mock: true,
      match_requests_on: [:query] do
      {:ok, [alert], feed_timestamp} = AlertProcessor.AlertsClient.get_alerts()
      result = AlertParser.parse_alert(alert, %{}, feed_timestamp)

      assert %AlertProcessor.Model.Alert{
               active_period: [%{start: _start_datetime, end: end_datetime}],
               created_at: created_at_datetime,
               duration_certainty: {:estimated, 14400},
               effect_name: "Delay",
               header: "Red Line experiencing minor delays",
               id: "115513",
               informed_entities: _informed_entities,
               service_effect: "Minor Red Line delay",
               severity: :minor,
               closed_timestamp: nil
             } = result

      assert 1_507_661_322 == feed_timestamp

      assert 36 * 60 * 60 ==
               DateTime.to_unix(end_datetime) - DateTime.to_unix(created_at_datetime)
    end
  end

  test "correctly parses an alert with a url" do
    use_cassette "estimated_url_alert",
      custom: true,
      clear_mock: true,
      match_requests_on: [:query] do
      {:ok, [alert], feed_timestamp} = AlertProcessor.AlertsClient.get_alerts()
      result = AlertParser.parse_alert(alert, %{}, feed_timestamp)
      assert result.url == "http://www.example.com/alert-info"
    end
  end

  test "correctly pulls the closed timestamp when present" do
    use_cassette "closed_alert", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, [alert], feed_timestamp} = AlertProcessor.AlertsClient.get_alerts()
      result = AlertParser.parse_alert(alert, %{}, feed_timestamp)

      assert %AlertProcessor.Model.Alert{
               active_period: [%{start: _start_datetime, end: _end_datetime}],
               created_at: _created_at_datetime,
               duration_certainty: :known,
               effect_name: "Delay",
               header: "Red Line experiencing minor delays",
               id: "115513",
               informed_entities: _informed_entities,
               service_effect: "Minor Red Line delay",
               severity: :minor,
               closed_timestamp: closed_timestamp
             } = result

      assert closed_timestamp == DT.from_erl!({{2017, 10, 10}, {17, 50, 59}}, "Etc/UTC")
    end
  end

  describe "remove_ignored/1" do
    @valid_alert %{
      "active_period" => [%{"start" => 1_507_661_322}],
      "last_push_notification_timestamp" => 1_507_661_322,
      "informed_entity" => [
        %{
          "activities" => ["BOARD", "EXIT", "RIDE"],
          "agency_id" => "1",
          "route_id" => "Boat-F1",
          "route_type" => 4,
          "trip" => %{
            "route_id" => "Boat-F1",
            "trip_id" => "Boat-F1-1000-Hingham-Weekday"
          }
        }
      ]
    }

    test "remove alert when informed_entity is not available" do
      assert AlertParser.remove_ignored([Map.delete(@valid_alert, "informed_entity")]) == []
    end

    test "remove alert when last_push_notification_timestamp is not available" do
      assert AlertParser.remove_ignored([
               Map.delete(@valid_alert, "last_push_notification_timestamp")
             ]) == []
    end

    test "remove alert when last_push_notification_timestamp is nil" do
      assert AlertParser.remove_ignored([
               %{@valid_alert | "last_push_notification_timestamp" => nil}
             ]) == []
    end

    test "remove alert when last_push_notification_timestamp is an empty string" do
      assert AlertParser.remove_ignored([
               %{@valid_alert | "last_push_notification_timestamp" => ""}
             ]) == []
    end

    test "do not remove alert when last_push_notification_timestamp and active_period are set" do
      assert length(AlertParser.remove_ignored([@valid_alert])) == 1
    end
  end

  describe "parse_translation/1" do
    test "parses list of translations" do
      # Note that a list of translations is not correct per the GTFS-realtime
      # spec but the feed we're working with does not currently follow the
      # GTFS-realtime spec. For details take a look here:
      # https://developers.google.com/transit/gtfs-realtime/reference/#message_translatedstring
      text = "some text"

      translation = [
        %{
          "translation" => %{
            "text" => text,
            "language" => "en"
          }
        }
      ]

      assert AlertParser.parse_translation(translation) == text
    end

    test "parses a translation map" do
      # Parses a `TranslatedString` type per:
      # https://developers.google.com/transit/gtfs-realtime/reference/#message_translatedstring
      text = "some text"

      translation = %{
        "translation" => [
          %{
            "text" => text,
            "language" => "en"
          }
        ]
      }

      assert AlertParser.parse_translation(translation) == text
    end
  end

  describe "parse_alert/1" do
    test "with alert with no active_period" do
      some_timestamp = 1_524_609_934

      alert = %{
        "id" => "some id",
        "created_timestamp" => some_timestamp,
        "duration_certainty" => nil,
        "effect_detail" => "some_effect",
        "header_text" => nil,
        "informed_entity" => [],
        "service_effect_text" => nil,
        "severity" => nil,
        "last_push_notification_timestamp" => some_timestamp
      }

      parsed_alert = AlertParser.parse_alert(alert, %{}, nil)
      refute parsed_alert.active_period
    end

    test "with direction_id for informed_entity" do
      informed_entity = %{
        "direction_id" => 0
      }

      some_timestamp = 1_524_609_934

      alert = %{
        "id" => "some id",
        "created_timestamp" => some_timestamp,
        "duration_certainty" => nil,
        "effect_detail" => "some_effect",
        "header_text" => nil,
        "informed_entity" => [informed_entity],
        "service_effect_text" => nil,
        "severity" => nil,
        "last_push_notification_timestamp" => some_timestamp
      }

      parsed_alert = AlertParser.parse_alert(alert, %{}, nil)
      [informed_entity] = parsed_alert.informed_entities
      assert informed_entity.direction_id == 0
    end

    test "adds schedule data to trip alerts" do
      use_cassette "trip_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, alerts, feed_timestamp} = AlertsClient.get_alerts()
        {:ok, facility_map} = ServiceInfoCache.get_facility_map()

        result =
          {alerts, facility_map, feed_timestamp}
          |> AlertParser.parse_alerts()
          |> Enum.flat_map(& &1.informed_entities)
          |> Enum.map(& &1.schedule)
          |> Enum.reject(&is_nil(&1))

        [schedule | _] = List.first(result)

        assert length(result) > 0

        assert %{
                 departure_time: "2017-10-26T08:52:00-04:00",
                 stop_id: "Newburyport",
                 trip_id: "CR-Saturday-Fall-17-1150"
               } = schedule
      end
    end

    test "with reminder_times" do
      some_timestamp = 1_524_609_934
      reminder_times = [1_515_166_200, 1_515_408_300]

      alert = %{
        "id" => "some id",
        "created_timestamp" => some_timestamp,
        "duration_certainty" => nil,
        "effect_detail" => "some_effect",
        "header_text" => nil,
        "informed_entity" => [],
        "service_effect_text" => nil,
        "severity" => nil,
        "last_push_notification_timestamp" => some_timestamp,
        "reminder_times" => reminder_times
      }

      parsed_alert = AlertParser.parse_alert(alert, %{}, nil)
      expected_reminder_times = Enum.map(reminder_times, &DateTime.from_unix!(&1))
      assert parsed_alert.reminder_times == expected_reminder_times
    end

    test "without reminder_times" do
      some_timestamp = 1_524_609_934

      alert = %{
        "id" => "some id",
        "created_timestamp" => some_timestamp,
        "duration_certainty" => nil,
        "effect_detail" => "some_effect",
        "header_text" => nil,
        "informed_entity" => [],
        "service_effect_text" => nil,
        "severity" => nil,
        "last_push_notification_timestamp" => some_timestamp
      }

      parsed_alert = AlertParser.parse_alert(alert, %{}, nil)
      assert parsed_alert.reminder_times == []
    end
  end

  test "swapped informed entities" do
    # the swap alerts cassette has been doctored so the IDs match in the API and IBI feeds
    use_cassette "swap_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      {alerts, api_alerts, updated_alerts} = AlertParser.process_alerts()
      informed_entities_before = List.first(alerts)["informed_entity"]
      informed_entities_after = List.first(updated_alerts)["informed_entity"]
      first_swapped_entity = List.first(informed_entities_after)
      informed_entities_api = List.first(api_alerts)["attributes"]["informed_entity"]
      first_api_entity = List.first(informed_entities_api)

      # the first informed entity from the API, in the format of the IBI feed
      # stop -> stop_id, route -> route_id, same activites and route_type
      # agency_id is droppend and trip becomes a map
      api_expected = %{
        "activities" => ["BOARD", "EXIT"],
        "route" => "47",
        "route_type" => 3,
        "stop" => "11809",
        "trip" => "trip-abc"
      }

      swapped_expected = %{
        "activities" => ["BOARD", "EXIT"],
        "route_id" => "47",
        "route_type" => 3,
        "stop_id" => "11809",
        "trip" => %{"route_id" => "47", "trip_id" => "trip-abc"}
      }

      assert first_swapped_entity["activities"] == first_api_entity["activities"]
      assert first_swapped_entity["route_type"] == first_api_entity["route_type"]
      assert first_swapped_entity["route_id"] == first_api_entity["route"]
      assert first_swapped_entity["stop_id"] == first_api_entity["stop"]
      assert first_swapped_entity["trip"]["trip_id"] == first_api_entity["trip"]
      assert first_swapped_entity["trip"]["route_id"] == first_api_entity["route"]
      refute informed_entities_before == informed_entities_after
      assert first_api_entity == api_expected
      assert first_swapped_entity == swapped_expected
    end
  end
end
