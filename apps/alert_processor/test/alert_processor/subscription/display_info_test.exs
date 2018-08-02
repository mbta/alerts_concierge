defmodule AlertProcessor.Subscriptions.DisplayInfoTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import AlertProcessor.Factory
  alias AlertProcessor.Subscription.DisplayInfo
  alias AlertProcessor.Model.InformedEntity

  @test_date Calendar.Date.from_ordinal!(2017, 193)

  describe "departure_times_for_subscriptions" do
    test "creates a map of trip => departure times for displaying" do
      use_cassette "schedule_display_info",
        custom: true,
        clear_mock: true,
        match_requests_on: [:query] do
        informed_entities = commuter_rail_subscription_entities()

        subscription =
          :subscription
          |> build(informed_entities: informed_entities)
          |> commuter_rail_subscription()
          |> weekday_subscription()

        assert {:ok,
                %{
                  "331" => ~T[17:10:00],
                  "221" => ~T[18:55:00]
                }} = DisplayInfo.departure_times_for_subscriptions([subscription], @test_date)
      end
    end

    test "with bad info" do
      use_cassette "schedule_display_info_bad",
        custom: true,
        clear_mock: true,
        match_requests_on: [:query] do
        informed_entities = [
          %InformedEntity{route_type: 2, route: "CR-Lowell", stop: "place-south"},
          %InformedEntity{route_type: 2, route: "CR-Lowell", stop: "place-north"}
        ]

        subscription =
          :subscription
          |> build(informed_entities: informed_entities)
          |> commuter_rail_subscription()
          |> weekday_subscription()

        assert {:ok, %{}} ==
                 DisplayInfo.departure_times_for_subscriptions([subscription], @test_date)
      end
    end

    test "with empty response" do
      use_cassette "schedule_display_info_empty",
        custom: true,
        clear_mock: true,
        match_requests_on: [:query] do
        informed_entities = [
          %InformedEntity{route_type: 4, activities: InformedEntity.default_entity_activities()},
          %InformedEntity{
            route_type: 4,
            route: "Boat-F1",
            direction_id: 1,
            activities: InformedEntity.default_entity_activities()
          },
          %InformedEntity{
            route_type: 4,
            route: "Boat-F1",
            stop: "Boat-Hingham",
            activities: ["BOARD"]
          },
          %InformedEntity{
            route_type: 4,
            route: "Boat-F1",
            stop: "Boat-Rowes",
            activities: ["EXIT"]
          }
        ]

        subscription =
          :subscription
          |> build(
            origin: "Boat-Hingham",
            destination: "Boat-Rowes",
            type: :ferry,
            informed_entities: informed_entities
          )
          |> saturday_subscription()

        assert {:ok, %{}} ==
                 DisplayInfo.departure_times_for_subscriptions([subscription], @test_date)
      end
    end
  end

  describe "station_names_for_subscriptions" do
    test "creates map of stop_id => stop name for displaying" do
      use_cassette "schedule_display_info",
        custom: true,
        clear_mock: true,
        match_requests_on: [:query] do
        informed_entities = commuter_rail_subscription_entities()

        subscription =
          :subscription
          |> build(informed_entities: informed_entities)
          |> commuter_rail_subscription()
          |> weekday_subscription()

        assert {:ok,
                %{
                  "place-north" => "North Station",
                  "Anderson/ Woburn" => "Anderson/Woburn"
                }} = DisplayInfo.station_names_for_subscriptions([subscription])
      end
    end

    test "with bad info" do
      use_cassette "schedule_display_info",
        custom: true,
        clear_mock: true,
        match_requests_on: [:query] do
        informed_entities = commuter_rail_subscription_entities()

        subscription =
          :subscription
          |> build(informed_entities: informed_entities)
          |> commuter_rail_subscription()
          |> Map.merge(%{origin: nil, destination: nil})
          |> weekday_subscription()

        assert {:ok, %{}} == DisplayInfo.station_names_for_subscriptions([subscription])
      end
    end
  end
end
