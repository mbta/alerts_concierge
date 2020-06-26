defmodule ConciergeSite.ScheduleTest do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
  use ExUnit.Case
  alias ConciergeSite.Schedule
  alias AlertProcessor.ExtendedTime
  alias AlertProcessor.Model.{Route, Subscription, TripInfo}

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
    destinations = ["place-GB-0316"]
    modes = ["cr"]

    result = Schedule.get_schedules_for_input(legs, origins, destinations, modes)

    assert is_map(result)
    assert Map.keys(result) == [{"cr", "CR-Newburyport"}]

    assert is_list(result[{"cr", "CR-Newburyport"}])
    assert Enum.all?(result[{"cr", "CR-Newburyport"}], &is_trip_info(&1))
    assert Enum.all?(result[{"cr", "CR-Newburyport"}], &Map.has_key?(&1, :weekend?))

    assert List.first(result[{"cr", "CR-Newburyport"}]) == %TripInfo{
             arrival_time: ~T[07:46:00],
             departure_time: ~T[06:35:00],
             arrival_extended_time: %ExtendedTime{relative_day: 1, time: ~T[07:46:00]},
             departure_extended_time: %ExtendedTime{relative_day: 1, time: ~T[06:35:00]},
             destination: {"Gloucester", "place-GB-0316", {42.616799, -70.668345}, 1},
             direction_id: 0,
             origin: {"North Station", "place-north", {42.365577, -71.06129}, 1},
             route: %Route{
               direction_names: ["Outbound", "Inbound"],
               headsigns: nil,
               route_id: "CR-Newburyport",
               route_type: 2,
               short_name: "",
               long_name: "Newburyport/Rockport Line",
               order: 10,
               stop_list: [
                 {"Rockport", "place-GB-0353", {42.655491, -70.627055}, 1},
                 {"Gloucester", "place-GB-0316", {42.616799, -70.668345}, 1},
                 {"West Gloucester", "place-GB-0296", {42.611933, -70.705417}, 1},
                 {"Manchester", "place-GB-0254", {42.573687, -70.77009}, 1},
                 {"Beverly Farms", "place-GB-0229", {42.561651, -70.811405}, 1},
                 {"Prides Crossing", "place-GB-0222", {42.559446, -70.825541}, 2},
                 {"Montserrat", "place-GB-0198", {42.562171, -70.869254}, 1},
                 {"Newburyport", "place-ER-0362", {42.797837, -70.87797}, 1},
                 {"Rowley", "place-ER-0312", {42.726845, -70.859034}, 1},
                 {"Ipswich", "place-ER-0276", {42.676921, -70.840589}, 1},
                 {"Hamilton/Wenham", "place-ER-0227", {42.609212, -70.874801}, 1},
                 {"North Beverly", "place-ER-0208", {42.583779, -70.883851}, 1},
                 {"Beverly", "place-ER-0183", {42.547276, -70.885432}, 1},
                 {"Salem", "place-ER-0168", {42.524792, -70.895876}, 1},
                 {"Swampscott", "place-ER-0128", {42.473743, -70.922537}, 1},
                 {"Lynn", "place-ER-0115", {42.462953, -70.945421}, 1},
                 {"River Works", "place-ER-0099", {42.449927, -70.969848}, 2},
                 {"Chelsea", "place-ER-0046", {42.395689, -71.034281}, 2},
                 {"North Station", "place-north", {42.365577, -71.06129}, 1}
               ],
               direction_destinations: ["Newburyport or Rockport", "North Station"]
             },
             selected: false,
             trip_number: "7101",
             weekend?: false
           }

    assert Enum.find_index(result[{"cr", "CR-Newburyport"}], & &1.weekend?) == 2
  end

  test "get_schedules_for_trip/2" do
    subscriptions = [
      %Subscription{
        destination: "place-WML-0442",
        destination_lat: 42.347581,
        destination_long: -71.099974,
        direction_id: 0,
        end_time: ~T[09:00:00.000000],
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
        start_time: ~T[08:00:00.000000],
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
        end_time: ~T[18:00:00.000000],
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
    assert Enum.all?(first_trip_result[{"cr", "CR-Worcester"}], &is_trip_info(&1))

    assert List.first(first_trip_result[{"cr", "CR-Worcester"}]) ==
             %AlertProcessor.Model.TripInfo{
               arrival_extended_time: %AlertProcessor.ExtendedTime{
                 relative_day: 1,
                 time: ~T[07:08:00]
               },
               arrival_time: ~T[07:08:00],
               departure_extended_time: %AlertProcessor.ExtendedTime{
                 relative_day: 1,
                 time: ~T[06:30:00]
               },
               departure_time: ~T[06:30:00],
               destination: {"Worcester", "place-WML-0442", {42.261461, -71.794888}, 1},
               direction_id: 0,
               selected: false,
               trip_number: "7503",
               weekend?: false,
               origin: {"Framingham", "place-WML-0214", {42.276108, -71.420055}, 1},
               route: %AlertProcessor.Model.Route{
                 direction_destinations: ["Worcester", "South Station"],
                 direction_names: ["Outbound", "Inbound"],
                 headsigns: nil,
                 long_name: "Framingham/Worcester Line",
                 order: 2,
                 route_id: "CR-Worcester",
                 route_type: 2,
                 short_name: "",
                 stop_list: [
                   {"Worcester", "place-WML-0442", {42.261461, -71.794888}, 1},
                   {"Grafton", "place-WML-0364", {42.2466, -71.685325}, 1},
                   {"Westborough", "place-WML-0340", {42.269644, -71.647076}, 1},
                   {"Southborough", "place-WML-0274", {42.267024, -71.524371}, 1},
                   {"Ashland", "place-WML-0252", {42.26149, -71.482161}, 1},
                   {"Framingham", "place-WML-0214", {42.276108, -71.420055}, 1},
                   {"West Natick", "place-WML-0199", {42.283064, -71.391797}, 1},
                   {"Natick Center", "place-WML-0177", {42.285719, -71.347133}, 2},
                   {"Wellesley Square", "place-WML-0147", {42.297526, -71.294173}, 2},
                   {"Wellesley Hills", "place-WML-0135", {42.31037, -71.277044}, 2},
                   {"Wellesley Farms", "place-WML-0125", {42.323608, -71.272288}, 2},
                   {"Auburndale", "place-WML-0102", {42.345725, -71.250826}, 2},
                   {"West Newton", "place-WML-0091", {42.347878, -71.230528}, 2},
                   {"Newtonville", "place-WML-0081", {42.351702, -71.205408}, 2},
                   {"Boston Landing", "place-WML-0035", {42.357293, -71.139883}, 1},
                   {"Lansdowne", "place-WML-0025", {42.347581, -71.099974}, 1},
                   {"Back Bay", "place-bbsta", {42.34735, -71.075727}, 1},
                   {"South Station", "place-sstat", {42.352271, -71.055242}, 1}
                 ]
               }
             }

    assert Enum.find_index(first_trip_result[{"cr", "CR-Worcester"}], & &1.weekend?) == 2

    assert is_map(return_trip_result)
    assert Map.keys(return_trip_result) == [{"cr", "CR-Worcester"}]
    assert is_list(return_trip_result[{"cr", "CR-Worcester"}])
    assert Enum.all?(return_trip_result[{"cr", "CR-Worcester"}], &is_trip_info(&1))

    assert List.first(return_trip_result[{"cr", "CR-Worcester"}]) ==
             %AlertProcessor.Model.TripInfo{
               arrival_extended_time: %AlertProcessor.ExtendedTime{
                 relative_day: 1,
                 time: ~T[05:26:00]
               },
               arrival_time: ~T[05:26:00],
               departure_extended_time: %AlertProcessor.ExtendedTime{
                 relative_day: 1,
                 time: ~T[04:45:00]
               },
               departure_time: ~T[04:45:00],
               direction_id: 1,
               origin: {"Worcester", "place-WML-0442", {42.261461, -71.794888}, 1},
               selected: false,
               trip_number: "500",
               weekend?: false,
               destination: {"Framingham", "place-WML-0214", {42.276108, -71.420055}, 1},
               route: %AlertProcessor.Model.Route{
                 direction_destinations: ["Worcester", "South Station"],
                 direction_names: ["Outbound", "Inbound"],
                 headsigns: nil,
                 long_name: "Framingham/Worcester Line",
                 order: 2,
                 route_id: "CR-Worcester",
                 route_type: 2,
                 short_name: "",
                 stop_list: [
                   {"Worcester", "place-WML-0442", {42.261461, -71.794888}, 1},
                   {"Grafton", "place-WML-0364", {42.2466, -71.685325}, 1},
                   {"Westborough", "place-WML-0340", {42.269644, -71.647076}, 1},
                   {"Southborough", "place-WML-0274", {42.267024, -71.524371}, 1},
                   {"Ashland", "place-WML-0252", {42.26149, -71.482161}, 1},
                   {"Framingham", "place-WML-0214", {42.276108, -71.420055}, 1},
                   {"West Natick", "place-WML-0199", {42.283064, -71.391797}, 1},
                   {"Natick Center", "place-WML-0177", {42.285719, -71.347133}, 2},
                   {"Wellesley Square", "place-WML-0147", {42.297526, -71.294173}, 2},
                   {"Wellesley Hills", "place-WML-0135", {42.31037, -71.277044}, 2},
                   {"Wellesley Farms", "place-WML-0125", {42.323608, -71.272288}, 2},
                   {"Auburndale", "place-WML-0102", {42.345725, -71.250826}, 2},
                   {"West Newton", "place-WML-0091", {42.347878, -71.230528}, 2},
                   {"Newtonville", "place-WML-0081", {42.351702, -71.205408}, 2},
                   {"Boston Landing", "place-WML-0035", {42.357293, -71.139883}, 1},
                   {"Lansdowne", "place-WML-0025", {42.347581, -71.099974}, 1},
                   {"Back Bay", "place-bbsta", {42.34735, -71.075727}, 1},
                   {"South Station", "place-sstat", {42.352271, -71.055242}, 1}
                 ]
               }
             }

    assert Enum.find_index(return_trip_result[{"cr", "CR-Worcester"}], & &1.weekend?) == 3
  end

  defp is_trip_info(%TripInfo{}), do: true
  defp is_trip_info(_), do: false
end
