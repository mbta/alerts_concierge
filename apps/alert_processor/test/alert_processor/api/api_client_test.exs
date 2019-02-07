defmodule AlertProcessor.ApiClientTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias AlertProcessor.{ApiClient}

  test "get_alerts/0 returns list of alerts if successful" do
    use_cassette "get_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert {:ok, [_ | _], [_ | _]} = ApiClient.get_alerts()
    end
  end

  describe "routes/2" do
    test "test with all defaults" do
      {:ok, routes} = ApiClient.routes()

      assert List.first(routes) == %{
               "attributes" => %{
                 "direction_destinations" => ["Fairmount", "South Station"],
                 "direction_names" => ["Outbound", "Inbound"],
                 "long_name" => "Fairmount Line",
                 "short_name" => "",
                 "type" => 2
               },
               "id" => "CR-Fairmount",
               "links" => %{"self" => "/routes/CR-Fairmount"},
               "relationships" => %{
                 "line" => %{"data" => %{"id" => "line-Fairmount", "type" => "line"}}
               },
               "type" => "route"
             }
    end

    test "test with a type value" do
      {:ok, routes} = ApiClient.routes([2])

      assert List.first(routes) == %{
               "attributes" => %{
                 "direction_destinations" => ["Fairmount", "South Station"],
                 "direction_names" => ["Outbound", "Inbound"],
                 "long_name" => "Fairmount Line",
                 "short_name" => "",
                 "type" => 2
               },
               "id" => "CR-Fairmount",
               "links" => %{"self" => "/routes/CR-Fairmount"},
               "relationships" => %{
                 "line" => %{"data" => %{"id" => "line-Fairmount", "type" => "line"}}
               },
               "type" => "route"
             }
    end
  end

  test "route_stops/1 returns inbound stops of a route" do
    expected_route_ids = [
      "Forge Park / 495",
      "Franklin",
      "Norfolk",
      "Walpole",
      "Plimptonville",
      "Windsor Gardens",
      "Norwood Central",
      "Norwood Depot",
      "Islington",
      "Dedham Corp Center",
      "Endicott",
      "Readville",
      "place-rugg",
      "place-bbsta",
      "place-sstat"
    ]

    use_cassette "stops_cr_franklin_inbound",
      custom: true,
      clear_mock: true,
      match_requests_on: [:query] do
      {:ok, routes} = ApiClient.route_stops("CR-Franklin")
      response_ids = routes |> Enum.map(& &1["id"])
      assert response_ids == expected_route_ids
    end
  end

  test "schedule_for_trip/1 returns list of schedules if successful" do
    use_cassette "trip_schedule_orange_line",
      custom: true,
      clear_mock: true,
      match_requests_on: [:query] do
      assert {:ok, _schedule_data} = ApiClient.schedule_for_trip("Orange")
    end
  end

  test "subway_schedules_union/2 returns list of schedules and included parent stations if successful" do
    use_cassette "subway_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert {:ok, _schedule_data, _included_data} =
               ApiClient.subway_schedules_union("place-brntn", "place-qamnl")
    end
  end
end
