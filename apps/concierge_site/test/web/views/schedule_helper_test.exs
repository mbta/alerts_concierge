defmodule ConciergeSite.ScheduleHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias ConciergeSite.ScheduleHelper

  test "render/2" do
    schedules = %{
      {"cr", "CR-Worcester"} => [
        %AlertProcessor.Model.TripInfo{
          departure_time: ~T[23:58:00],
          origin: {"Auburndale", "Auburndale", {42.345725, -71.250826}, 2},
          trip_number: "537"
        }
      ],
      {"ferry", "Boat-F4"} => [
        %AlertProcessor.Model.TripInfo{
          departure_time: ~T[06:30:00],
          origin: {"Boston (Long Wharf)", "Boat-Long", {42.360018, -71.050247}, 1},
          trip_number: ""
        }
      ]
    }

    html = Phoenix.HTML.safe_to_string(ScheduleHelper.render(schedules, "start_input", "end_input"))

    assert html =~ "Commuter Rail trains scheduled in this time for CR-Worcester"
    assert html =~ "Ferry boats scheduled in this time for Boat-F4"
    assert html =~ "Train 537, Auburndale, 11:58pm"
    assert html =~ "Boston (Long Wharf),  6:30am"
  end
end
