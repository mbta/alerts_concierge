defmodule ConciergeSite.ScheduleHelperTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ConciergeSite.ScheduleHelper

  test "render/5" do
    schedules = %{
      {"cr", "CR-Worcester"} => [
        %AlertProcessor.Model.TripInfo{
          departure_time: ~T[23:58:00],
          origin: {"Auburndale", "place-WML-0102", {42.345725, -71.250826}, 2},
          trip_number: "537",
          route: %{
            route_id: "CR-Worcester"
          }
        }
      ],
      {"ferry", "Boat-F4"} => [
        %AlertProcessor.Model.TripInfo{
          departure_time: ~T[06:30:00],
          origin: {"Boston (Long Wharf)", "Boat-Long", {42.360018, -71.050247}, 1},
          trip_number: "",
          route: %{
            route_id: "Boat-F4"
          }
        }
      ]
    }

    html =
      Phoenix.HTML.safe_to_string(
        ScheduleHelper.render(schedules, "trip_start_time", "trip_return_start_time")
      )

    assert html =~ "I take these Commuter Rail trains:"
    assert html =~ "I take these Ferry boats:"
    assert html =~ "Train 537 from Auburndale, 11:58pm"
    assert html =~ "Ferry from Boston (Long Wharf), 06:30am"
  end

  test "render/5 poses prompts in the form of questions when requested" do
    schedules = %{
      {"cr", "CR-Worcester"} => [
        %AlertProcessor.Model.TripInfo{
          departure_time: ~T[23:58:00],
          origin: {"Auburndale", "place-WML-0102", {42.345725, -71.250826}, 2},
          trip_number: "537",
          route: %{
            route_id: "CR-Worcester"
          }
        }
      ],
      {"ferry", "Boat-F4"} => [
        %AlertProcessor.Model.TripInfo{
          departure_time: ~T[06:30:00],
          origin: {"Boston (Long Wharf)", "Boat-Long", {42.360018, -71.050247}, 1},
          trip_number: "",
          route: %{
            route_id: "Boat-F4"
          }
        }
      ]
    }

    html =
      Phoenix.HTML.safe_to_string(
        ScheduleHelper.render(schedules, "trip_start_time", "trip_return_start_time", %{}, true)
      )

    assert html =~ "Which Commuter Rail trains would you like alerts about?"
    assert html =~ "Which Ferry boats would you like alerts about?"
  end
end
