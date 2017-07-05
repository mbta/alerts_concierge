defmodule ConciergeSite.Subscriptions.DisplayInfoTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import AlertProcessor.Factory
  alias ConciergeSite.Subscriptions.DisplayInfo
  alias AlertProcessor.Model.InformedEntity

  describe "departure_times_for_subscriptions" do
    test "creates a map of trip => departure times for displaying" do
      use_cassette "schedule_display_info", custom: true, clear_mock: true, match_requests_on: [:query] do
        informed_entities = commuter_rail_subscription_entities()
        subscription =
          :subscription
          |> build(informed_entities: informed_entities)
          |> commuter_rail_subscription()
          |> weekday_subscription()

        {:ok, %{
          "331" => "5:10pm",
          "221" => "6:55pm"
        }} = DisplayInfo.departure_times_for_subscriptions([subscription])
      end
    end

    test "departure_times_for_subscriptions with bad info" do
      use_cassette "schedule_display_info", custom: true, clear_mock: true, match_requests_on: [:query] do
        informed_entities = [
          %InformedEntity{route_type: 2, route: "CR-Lowell", stop: "place-south"},
          %InformedEntity{route_type: 2, route: "CR-Lowell", stop: "place-north"}
        ]

        subscription =
          :subscription
          |> build(informed_entities: informed_entities)
          |> commuter_rail_subscription()
          |> weekday_subscription()

        {:ok, %{}} == DisplayInfo.departure_times_for_subscriptions([subscription])
      end
    end
  end
end
