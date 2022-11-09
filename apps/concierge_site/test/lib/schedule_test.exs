defmodule ConciergeSite.ScheduleTest do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
  use ExUnit.Case
  alias ConciergeSite.Schedule
  alias AlertProcessor.Model.{Subscription, TripInfo}

  doctest Schedule

  test "remove_shuttle_schedules/2" do
    shuttle_schedule = %{
      "relationships" => %{
        "route" => %{
          "data" => %{"id" => "shuttle-route", "type" => "route"}
        }
      }
    }

    line_schedule = %{
      "relationships" => %{
        "route" => %{
          "data" => %{"id" => "line-route", "type" => "route"}
        }
      }
    }

    assert [line_schedule] ==
             Schedule.remove_shuttle_schedules([shuttle_schedule, line_schedule], "line-route")
  end

  test "get_schedules_for_input/4" do
    legs = ["CR-Newburyport"]
    origins = ["place-north"]
    destinations = ["place-GB-0254"]
    modes = ["cr"]

    result = Schedule.get_schedules_for_input(legs, origins, destinations, modes)

    assert is_map(result)
    assert Map.keys(result) == [{"cr", "CR-Newburyport"}]

    assert is_list(result[{"cr", "CR-Newburyport"}])
    assert Enum.all?(result[{"cr", "CR-Newburyport"}], &is_trip_info(&1))
    assert Enum.all?(result[{"cr", "CR-Newburyport"}], &Map.has_key?(&1, :weekend?))
  end

  test "get_schedules_for_trip/2" do
    subscriptions = [
      %Subscription{
        destination: "place-WML-0442",
        destination_lat: 42.347581,
        destination_long: -71.099974,
        direction_id: 0,
        end_time: ~T[09:00:00],
        facility_types: [:bike_storage],
        id: "9eb0d744-d1e5-477b-a78b-d466a182b990",
        inserted_at: ~N[2018-07-09 19:12:22.307235],
        notification_type_to_send: nil,
        origin: "place-WML-0214",
        origin_lat: 42.352271,
        origin_long: -71.055242,
        rank: 0,
        relevant_days: [:monday, :tuesday, :wednesday, :thursday, :friday],
        return_trip: false,
        route: "CR-Worcester",
        route_type: 2,
        start_time: ~T[08:00:00],
        travel_end_time: nil,
        travel_start_time: nil,
        trip_id: "f3ebb29d-8770-4024-8bd3-ae131093b6df",
        type: :cr,
        updated_at: ~N[2018-07-09 19:12:22.307245],
        user_id: "a429862d-23f4-4015-9303-cb2aa58c4108"
      },
      %Subscription{
        destination: "place-WML-0214",
        destination_lat: 42.352271,
        destination_long: -71.055242,
        direction_id: 1,
        end_time: ~T[18:00:00],
        facility_types: [:bike_storage],
        id: "0d3ba736-420b-4c19-9f06-91ebeadb177a",
        inserted_at: ~N[2018-07-09 19:12:22.350058],
        notification_type_to_send: nil,
        origin: "place-WML-0442",
        origin_lat: 42.347581,
        origin_long: -71.099974,
        rank: 0,
        relevant_days: [:monday, :tuesday, :wednesday, :thursday, :friday],
        return_trip: true,
        route: "CR-Worcester",
        route_type: 2,
        start_time: ~T[17:00:00],
        travel_end_time: nil,
        travel_start_time: nil,
        trip_id: "f3ebb29d-8770-4024-8bd3-ae131093b6df",
        type: :cr,
        updated_at: ~N[2018-07-09 19:12:22.350070],
        user_id: "a429862d-23f4-4015-9303-cb2aa58c4108"
      }
    ]

    first_trip_result = Schedule.get_schedules_for_trip(subscriptions, false)
    return_trip_result = Schedule.get_schedules_for_trip(subscriptions, true)

    assert is_map(first_trip_result)
    assert Map.keys(first_trip_result) == [{"cr", "CR-Worcester"}]
    assert is_list(first_trip_result[{"cr", "CR-Worcester"}])
    assert Enum.all?(first_trip_result[{"cr", "CR-Worcester"}], &is_trip_info(&1))

    assert is_map(return_trip_result)
    assert Map.keys(return_trip_result) == [{"cr", "CR-Worcester"}]
    assert is_list(return_trip_result[{"cr", "CR-Worcester"}])
    assert Enum.all?(return_trip_result[{"cr", "CR-Worcester"}], &is_trip_info(&1))
  end

  defp is_trip_info(%TripInfo{}), do: true
  defp is_trip_info(_), do: false
end
