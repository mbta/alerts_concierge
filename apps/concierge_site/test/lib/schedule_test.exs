defmodule ConciergeSite.ScheduleTest do
  use ExUnit.Case
  alias ConciergeSite.Schedule
  alias AlertProcessor.Model.{Route, Subscription, TripInfo}

  doctest Schedule

  test "get_schedules_for_input/4" do
    legs = ["CR-Worcester"]
    origins = ["place-sstat"]
    destinations = ["Yawkey"]
    modes = ["cr"]

    result = Schedule.get_schedules_for_input(legs, origins, destinations, modes)

    assert is_map(result)
    assert Map.keys(result) == [{"cr", "CR-Worcester"}]
    assert is_list(result[{"cr", "CR-Worcester"}])
    assert Enum.all?(result[{"cr", "CR-Worcester"}], &(is_trip_info(&1)))
    assert List.first(result[{"cr", "CR-Worcester"}]) == %TripInfo{
      arrival_time: ~T[05:40:00],
      departure_time: ~T[05:30:00],
      destination: {"Yawkey", "Yawkey", {42.347581, -71.099974}, 1},
      direction_id: 0,
      origin: {"South Station", "place-sstat", {42.352271, -71.055242}, 1},
      route: %Route{
        direction_names: ["Outbound", "Inbound"],
        headsigns: nil,
        long_name: "Framingham/Worcester Line",
        order: 2,
        route_id: "CR-Worcester",
        route_type: 2,
        short_name: "",
        stop_list: [
          {"Worcester", "Worcester", {42.261461, -71.794888}, 1},
          {"Grafton", "Grafton", {42.2466, -71.685325}, 1},
          {"Westborough", "Westborough", {42.269644, -71.647076}, 1},
          {"Southborough", "Southborough", {42.267024, -71.524371}, 1},
          {"Ashland", "Ashland", {42.26149, -71.482161}, 1},
          {"Framingham", "Framingham", {42.276719, -71.416792}, 1},
          {"West Natick", "West Natick", {42.283064, -71.391797}, 1},
          {"Natick Center", "Natick Center", {42.285719, -71.347133}, 2},
          {"Wellesley Square", "Wellesley Square", {42.297526, -71.294173}, 2},
          {"Wellesley Hills", "Wellesley Hills", {42.31037, -71.277044}, 2},
          {"Wellesley Farms", "Wellesley Farms", {42.323608, -71.272288}, 2},
          {"Auburndale", "Auburndale", {42.345725, -71.250826}, 2},
          {"West Newton", "West Newton", {42.347878, -71.230528}, 2},
          {"Newtonville", "Newtonville", {42.351603, -71.207338}, 2},
          {"Boston Landing", "Boston Landing", {42.357293, -71.139883}, 1},
          {"Yawkey", "Yawkey", {42.347581, -71.099974}, 1},
          {"Back Bay", "place-bbsta", {42.34735, -71.075727}, 1},
          {"South Station", "place-sstat", {42.352271, -71.055242}, 1}
        ]
      },
      selected: false,
      trip_number: "583"
    }
  end

  test "get_schedules_for_trip/2" do
    subscriptions = [
      %Subscription{
        alert_priority_type: :low,
        destination: "Yawkey",
        destination_lat: 42.347581,
        destination_long: -71.099974,
        direction_id: 0,
        end_time: ~T[09:00:00.000000],
        facility_types: [:bike_storage],
        id: "9eb0d744-d1e5-477b-a78b-d466a182b990",
        inserted_at: ~N[2018-07-09 19:12:22.307235],
        notification_type_to_send: nil,
        origin: "place-sstat",
        origin_lat: 42.352271,
        origin_long: -71.055242,
        rank: 0,
        relevant_days: [:monday, :tuesday, :wednesday, :thursday, :friday],
        return_trip: false,
        route: "CR-Worcester",
        route_type: 2,
        start_time: ~T[08:00:00.000000],
        travel_end_time: nil,
        travel_start_time: nil,
        trip_id: "f3ebb29d-8770-4024-8bd3-ae131093b6df",
        type: :cr,
        updated_at: ~N[2018-07-09 19:12:22.307245],
        user_id: "a429862d-23f4-4015-9303-cb2aa58c4108"
      },
      %Subscription{
        alert_priority_type: :low,
        destination: "place-sstat",
        destination_lat: 42.352271,
        destination_long: -71.055242,
        direction_id: 1,
        end_time: ~T[18:00:00.000000],
        facility_types: [:bike_storage],
        id: "0d3ba736-420b-4c19-9f06-91ebeadb177a",
        inserted_at: ~N[2018-07-09 19:12:22.350058],
        notification_type_to_send: nil,
        origin: "Yawkey",
        origin_lat: 42.347581,
        origin_long: -71.099974,
        rank: 0,
        relevant_days: [:monday, :tuesday, :wednesday, :thursday, :friday],
        return_trip: true,
        route: "CR-Worcester",
        route_type: 2,
        start_time: ~T[17:00:00.000000],
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
    assert Enum.all?(first_trip_result[{"cr", "CR-Worcester"}], &(is_trip_info(&1)))
    assert List.first(first_trip_result[{"cr", "CR-Worcester"}]) == %TripInfo{
      arrival_time: ~T[05:40:00],
      departure_time: ~T[05:30:00],
      destination: {"Yawkey", "Yawkey", {42.347581, -71.099974}, 1},
      direction_id: 0,
      origin: {"South Station", "place-sstat", {42.352271, -71.055242}, 1},
      route: %AlertProcessor.Model.Route{
        direction_names: ["Outbound", "Inbound"],
        headsigns: nil,
        long_name: "Framingham/Worcester Line",
        order: 2,
        route_id: "CR-Worcester",
        route_type: 2,
        short_name: "",
        stop_list: [
          {"Worcester", "Worcester", {42.261461, -71.794888}, 1},
          {"Grafton", "Grafton", {42.2466, -71.685325}, 1},
          {"Westborough", "Westborough", {42.269644, -71.647076}, 1},
          {"Southborough", "Southborough", {42.267024, -71.524371}, 1},
          {"Ashland", "Ashland", {42.26149, -71.482161}, 1},
          {"Framingham", "Framingham", {42.276719, -71.416792}, 1},
          {"West Natick", "West Natick", {42.283064, -71.391797}, 1},
          {"Natick Center", "Natick Center", {42.285719, -71.347133}, 2},
          {"Wellesley Square", "Wellesley Square", {42.297526, -71.294173}, 2},
          {"Wellesley Hills", "Wellesley Hills", {42.31037, -71.277044}, 2},
          {"Wellesley Farms", "Wellesley Farms", {42.323608, -71.272288}, 2},
          {"Auburndale", "Auburndale", {42.345725, -71.250826}, 2},
          {"West Newton", "West Newton", {42.347878, -71.230528}, 2},
          {"Newtonville", "Newtonville", {42.351603, -71.207338}, 2},
          {"Boston Landing", "Boston Landing", {42.357293, -71.139883}, 1},
          {"Yawkey", "Yawkey", {42.347581, -71.099974}, 1},
          {"Back Bay", "place-bbsta", {42.34735, -71.075727}, 1},
          {"South Station", "place-sstat", {42.352271, -71.055242}, 1}
        ]
      },
      selected: false,
      trip_number: "583"    
    }

    assert is_map(return_trip_result)
    assert Map.keys(return_trip_result) == [{"cr", "CR-Worcester"}]
    assert is_list(return_trip_result[{"cr", "CR-Worcester"}])
    assert Enum.all?(return_trip_result[{"cr", "CR-Worcester"}], &(is_trip_info(&1)))
    assert List.first(return_trip_result[{"cr", "CR-Worcester"}]) == %TripInfo{
      arrival_time: ~T[06:20:00],
      departure_time: ~T[06:09:00],
      destination: {"South Station", "place-sstat", {42.352271, -71.055242}, 1},
      direction_id: 1,
      origin: {"Yawkey", "Yawkey", {42.347581, -71.099974}, 1},
      route: %AlertProcessor.Model.Route{
        direction_names: ["Outbound", "Inbound"],
        headsigns: nil,
        long_name: "Framingham/Worcester Line",
        order: 2,
        route_id: "CR-Worcester",
        route_type: 2,
        short_name: "",
        stop_list: [
          {"Worcester", "Worcester", {42.261461, -71.794888}, 1},
          {"Grafton", "Grafton", {42.2466, -71.685325}, 1},
          {"Westborough", "Westborough", {42.269644, -71.647076}, 1},
          {"Southborough", "Southborough", {42.267024, -71.524371}, 1},
          {"Ashland", "Ashland", {42.26149, -71.482161}, 1},
          {"Framingham", "Framingham", {42.276719, -71.416792}, 1},
          {"West Natick", "West Natick", {42.283064, -71.391797}, 1},
          {"Natick Center", "Natick Center", {42.285719, -71.347133}, 2},
          {"Wellesley Square", "Wellesley Square", {42.297526, -71.294173}, 2},
          {"Wellesley Hills", "Wellesley Hills", {42.31037, -71.277044}, 2},
          {"Wellesley Farms", "Wellesley Farms", {42.323608, -71.272288}, 2},
          {"Auburndale", "Auburndale", {42.345725, -71.250826}, 2},
          {"West Newton", "West Newton", {42.347878, -71.230528}, 2},
          {"Newtonville", "Newtonville", {42.351603, -71.207338}, 2},
          {"Boston Landing", "Boston Landing", {42.357293, -71.139883}, 1},
          {"Yawkey", "Yawkey", {42.347581, -71.099974}, 1},
          {"Back Bay", "place-bbsta", {42.34735, -71.075727}, 1},
          {"South Station", "place-sstat", {42.352271, -71.055242}, 1}
        ]
      },
      selected: false,
      trip_number: "500"    
    }
  end

  defp is_trip_info(%TripInfo{}), do: true
  defp is_trip_info(_), do: false
end
