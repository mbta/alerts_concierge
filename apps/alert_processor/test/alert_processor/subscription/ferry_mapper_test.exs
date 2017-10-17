defmodule AlertProcessor.Subscription.FerryMapperTest do
  use AlertProcessor.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import AlertProcessor.Factory
  alias AlertProcessor.{Model.InformedEntity, Model.Trip, Subscription.FerryMapper}

  describe "map_subscriptions one way" do
    @one_way_params %{
      "origin" => "Boat-Long",
      "destination" => "Boat-Hingham",
      "trips" => ["Boat-F1-Boat-Long-18:05:00-weekday-0", "Boat-F1-Boat-Long-21:10:00-weekday-0"],
      "relevant_days" => ["weekday"],
      "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
      "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
      "return_start" => nil,
      "return_end" => nil,
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "constructs subscription with severity" do
      {:ok, [{subscription, _ie}]} = FerryMapper.map_subscriptions(@one_way_params)
      assert subscription.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{subscription, _ie}]} = FerryMapper.map_subscriptions(@one_way_params)
      assert subscription.type == :ferry
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{subscription, _ie}]} = FerryMapper.map_subscriptions(@one_way_params)
      assert subscription.origin == "Boat-Long"
      assert subscription.destination == "Boat-Hingham"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{subscription, _ie}]} = FerryMapper.map_subscriptions(@one_way_params)
      assert subscription.start_time == ~T[12:00:00]
      assert subscription.end_time == ~T[14:00:00]
      assert subscription.relevant_days == [:weekday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      amenity_informed_entities_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "Boat-Long"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route in other direction" do
      reverse_trip_params = Map.merge(@one_way_params, %{"destination" => "Boat-Long", "origin" => "Boat-Hingham"})
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(reverse_trip_params)
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      route_type_entity_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 4}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      stop_entities = Enum.filter(informed_entities, &InformedEntity.entity_type(&1) == :stop)
      assert Enum.all?(stop_entities, & match?(%InformedEntity{route: "Boat-F1", route_type: 4, direction_id: nil}, &1) || match?(%InformedEntity{route: "Boat-F1", route_type: 4, direction_id: 0}, &1))
    end

    test "constructs subscription with trips" do
      {:ok, [{_sub, informed_entities}]} = FerryMapper.map_subscriptions(@one_way_params)
      trip_1805_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-Boat-Long-18:05:00-weekday-0"}, informed_entity)
        end)
      assert trip_1805_count == 1
      trip_2110_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-Boat-Long-21:10:00-weekday-0"}, informed_entity)
        end)
      assert trip_2110_count == 1
      trip_count =
        Enum.count(informed_entities, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 2
    end
  end

  describe "map_subscriptions round trip" do
    @round_trip_params %{
      "origin" => "Boat-Long",
      "destination" => "Boat-Hingham",
      "trips" => ["Boat-F1-Boat-Long-18:05:00-weekday-0", "Boat-F1-Boat-Long-21:10:00-weekday-0"],
      "return_trips" => ["Boat-F1-Boat-Hingham-21:00:00-weekday-1"],
      "relevant_days" => ["weekday"],
      "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
      "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
      "return_start" => DateTime.from_naive!(~N[2017-07-20 18:00:00], "Etc/UTC"),
      "return_end" => DateTime.from_naive!(~N[2017-07-20 20:00:00], "Etc/UTC"),
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "constructs subscription with severity" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      assert sub1.alert_priority_type == :low
      assert sub2.alert_priority_type == :low
    end

    test "constructs subscription with type" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      assert sub1.type == :ferry
      assert sub2.type == :ferry
    end

    test "constructs subscription with origin and destination" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      assert sub1.origin == "Boat-Long"
      assert sub1.destination == "Boat-Hingham"
      assert sub2.origin == "Boat-Hingham"
      assert sub2.destination == "Boat-Long"
    end

    test "constructs subscription with timeframe" do
      {:ok, [{sub1, _ie1}, {sub2, _ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      assert sub1.start_time == ~T[12:00:00]
      assert sub1.end_time == ~T[14:00:00]
      assert sub1.relevant_days == [:weekday]
      assert sub2.start_time == ~T[18:00:00]
      assert sub2.end_time == ~T[20:00:00]
      assert sub2.relevant_days == [:weekday]
    end

    test "constructs subscription with amenities" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      amenity_informed_entities_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "Boat-Long"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
      amenity_informed_entities_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{facility_type: :elevator, stop: "Boat-Long"}, informed_entity)
        end)
      assert amenity_informed_entities_count == 1
    end

    test "constructs subscription with route" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: 0}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: nil}, informed_entity)
        end)
      assert route_entity_count == 1
      route_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: "Boat-F1", route_type: 4, stop: nil, direction_id: 1}, informed_entity)
        end)
      assert route_entity_count == 1
    end

    test "constructs subscription with route type" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      route_type_entity_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 4}, informed_entity)
        end)
      assert route_type_entity_count == 1
      route_type_entity_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{route: nil, route_type: 4}, informed_entity)
        end)
      assert route_type_entity_count == 1
    end

    test "constructs subscription with stops" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      stop_entities1 = Enum.filter(ie1, &InformedEntity.entity_type(&1) == :stop)
      stop_entities2 = Enum.filter(ie2, &InformedEntity.entity_type(&1) == :stop)
      assert Enum.all?(stop_entities1, & match?(%InformedEntity{route: "Boat-F1", route_type: 4, direction_id: nil}, &1) || match?(%InformedEntity{route: "Boat-F1", route_type: 4, direction_id: 0}, &1))
      assert Enum.all?(stop_entities2, & match?(%InformedEntity{route: "Boat-F1", route_type: 4, direction_id: nil}, &1) || match?(%InformedEntity{route: "Boat-F1", route_type: 4, direction_id: 1}, &1))
    end

    test "constructs subscription with trips" do
      {:ok, [{_sub1, ie1}, {_sub2, ie2}]} = FerryMapper.map_subscriptions(@round_trip_params)
      trip_1805_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-Boat-Long-18:05:00-weekday-0"}, informed_entity)
        end)
      assert trip_1805_count == 1
      trip_2110_count =
        Enum.count(ie1, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-Boat-Long-21:10:00-weekday-0"}, informed_entity)
        end)
      assert trip_2110_count == 1
      trip_count =
        Enum.count(ie1, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 2

      trip_2100_count =
        Enum.count(ie2, fn(informed_entity) ->
          match?(%InformedEntity{trip: "Boat-F1-Boat-Hingham-21:00:00-weekday-1"}, informed_entity)
        end)
      assert trip_2100_count == 1
      trip_count =
        Enum.count(ie2, fn(informed_entity) ->
          InformedEntity.entity_type(informed_entity) == :trip
        end)
      assert trip_count == 1
    end
  end

  describe "map_trip_options" do
    @test_date Calendar.Date.from_ordinal!(2017, 226)

    test "returns inbound results for origin destination" do
      use_cassette "long_wharf_to_hingham_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = FerryMapper.map_trip_options("Boat-Long", "Boat-Hingham", :weekday, @test_date)
        assert Enum.all?(trips, &match?(&1, %Trip{destination: {"Hingham (Hewitt's Cove)", "Boat-Hingham"}, direction_id: 0, origin: {"Boston (Long Wharf)", "Boat-Long"}}))
      end
    end

    test "returns outbound results for origin destination" do
      use_cassette "hingham_to_long_wharf_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        {:ok, trips} = FerryMapper.map_trip_options("Boat-Hingham", "Boat-Long", :weekday, @test_date)
        assert Enum.all?(trips, &match?(&1, %Trip{destination: {"Boston (Long Wharf)", "Boat-Long"}, direction_id: 1, origin: {"Hingham (Hewitt's Cove)", "Boat-Hingham"}}))
      end
    end

    test "returns error for invalid origin destination combo" do
      assert :error = FerryMapper.map_trip_options("Boat-Charlestown", "Boat-Hingham", :weekday, @test_date)
    end
  end

  describe "get_trip_info" do
    test "returns trip options with closest trip preselected" do
      {:ok, trips} = FerryMapper.get_trip_info("Boat-Hingham", "Boat-Long", :weekday, [])
      selected_trip = trips |> Enum.at(2) |> Map.get(:departure_time) |> Time.to_string()
      {:ok, with_selected_trip} = FerryMapper.get_trip_info("Boat-Hingham", "Boat-Long", :weekday, selected_trip)

      assert [%{selected: false}, %{selected: false}, %{selected: true}, %{selected: false} | _] = with_selected_trip
    end

    test "returns trip options with preselected values" do
      {:ok, trips} = FerryMapper.get_trip_info("Boat-Hingham", "Boat-Long", :weekday, [])
      selected_trips = [Enum.at(trips, 1).trip_number]
      {:ok, with_selected_trips} = FerryMapper.get_trip_info("Boat-Hingham", "Boat-Long", :weekday, selected_trips)

      assert [%{selected: false}, %{selected: true}, %{selected: false} | _] = with_selected_trips
    end

    test "returns error if origin/destination are not on the same route" do
      :error = FerryMapper.get_trip_info("Boat-Hingham", "Boat-Charlestown", :sunday, "10:00:00")
      :error = FerryMapper.get_trip_info("Boat-Hingham", "Boat-Charlestown", :sunday, ["Boat-F1-Boat-Hingham-11:00:00-weekend-1", "Boat-F1-Boat-Hingham-15:00:00-weekend-1"])
      :error = FerryMapper.get_trip_info("Boat-Long", "Boat-Rowes", :weekday, "10:00:00")
    end
  end

  describe "populate_trip_options one_way" do
    test "one_way with timestamp returns trip options with closest trip preselected" do
      params = %{
        "origin" => "Boat-Hingham",
        "destination" => "Boat-Long",
        "relevant_days" => "weekday",
        "departure_start" => "10:00:00",
        "trip_type" => "one_way"
      }
      {:ok, %{departure_trips: departure_trips}} = FerryMapper.populate_trip_options(params)
      selected_trips = Enum.filter(departure_trips, & &1.selected)
      assert [%Trip{departure_time: ~T[10:00:00], selected: true}] = selected_trips
    end

    test "one_way with trip_ids returns trip options with preselected trips" do
      params = %{
        "origin" => "Boat-Hingham",
        "destination" => "Boat-Long",
        "relevant_days" => "weekday",
        "trips" => ["Boat-F1-Boat-Hingham-13:00:00-weekday-1", "Boat-F1-Boat-Hingham-15:00:00-weekday-1"],
        "trip_type" => "one_way"
      }
      {:ok, %{departure_trips: departure_trips}} = FerryMapper.populate_trip_options(params)
      selected_trips = Enum.filter(departure_trips, & &1.selected)
      assert [
        %Trip{trip_number: "Boat-F1-Boat-Hingham-13:00:00-weekday-1", selected: true},
        %Trip{trip_number: "Boat-F1-Boat-Hingham-15:00:00-weekday-1", selected: true}
      ] = selected_trips
    end

    test "one_way with_timestamp returns error and message with invalid origin/destination combo" do
      params = %{
        "origin" => "Boat-Hingham",
        "destination" => "Boat-Charlestown",
        "relevant_days" => "weekday",
        "departure_start" => "10:00:00",
        "trip_type" => "one_way"
      }
      {:error, _} = FerryMapper.populate_trip_options(params)
    end

    test "one_way with trip_ids returns error and message with invalid origin/destination combo" do
      params = %{
        "origin" => "Boat-Hingham",
        "destination" => "Boat-Charlestown",
        "relevant_days" => "weekday",
        "trips" => ["Boat-F1-Boat-Hingham-13:00:00-weekday-1", "Boat-F1-Boat-Hingham-15:00:00-weekday-1"],
        "trip_type" => "one_way"
      }
      {:error, _} = FerryMapper.populate_trip_options(params)
    end
  end

  describe "populate_trip_options round_trip" do
    test "round_trip with timestamp returns trip options with closest trip preselected" do
      params = %{
        "origin" => "Boat-Hingham",
        "destination" => "Boat-Long",
        "relevant_days" => "weekday",
        "departure_start" => "10:00:00",
        "return_start" => "16:00:00",
        "trip_type" => "round_trip"
      }
      {:ok, %{
          departure_trips: departure_trips,
          return_trips: return_trips
        }
      } = FerryMapper.populate_trip_options(params)
      selected_trips = Enum.filter(departure_trips, & &1.selected)
      selected_return_trips = Enum.filter(return_trips, & &1.selected)
      assert [
        %Trip{trip_number: "Boat-F1-Boat-Hingham-10:00:00-weekday-1", selected: true},
      ] = selected_trips
      assert [
        %Trip{trip_number: "Boat-F1-Boat-Long-15:40:00-weekday-0", selected: true}
      ] = selected_return_trips
    end

    test "round_trip with trip_ids returns trip options with preselected trips" do
      params = %{
        "origin" => "Boat-Hingham",
        "destination" => "Boat-Long",
        "relevant_days" => "weekday",
        "trips" => ["Boat-F1-Boat-Hingham-13:00:00-weekday-1", "Boat-F1-Boat-Hingham-15:00:00-weekday-1"],
        "return_trips" => ["Boat-F1-Boat-Long-14:00:00-weekday-0", "Boat-F1-Boat-Long-16:30:00-weekday-0"],
        "trip_type" => "round_trip"
      }
      {:ok, %{
          departure_trips: departure_trips,
          return_trips: return_trips
        }
      } = FerryMapper.populate_trip_options(params)
      selected_trips = Enum.filter(departure_trips, & &1.selected)
      selected_return_trips = Enum.filter(return_trips, & &1.selected)
      assert [
        %Trip{trip_number: "Boat-F1-Boat-Hingham-13:00:00-weekday-1", selected: true},
        %Trip{trip_number: "Boat-F1-Boat-Hingham-15:00:00-weekday-1", selected: true}
      ] = selected_trips
      assert [
        %Trip{trip_number: "Boat-F1-Boat-Long-14:00:00-weekday-0", selected: true},
        %Trip{trip_number: "Boat-F1-Boat-Long-16:30:00-weekday-0", selected: true}
      ] = selected_return_trips
    end

    test "round_trip with_timestamp returns error and message with invalid origin/destination combo" do
      params = %{
        "origin" => "Boat-Hingham",
        "destination" => "Boat-Charlestown",
        "relevant_days" => "weekday",
        "departure_start" => "10:00:00",
        "return_start" => "16:00:00",
        "trip_type" => "round_trip"
      }
      {:error, _} = FerryMapper.populate_trip_options(params)
    end

    test "round_trip with trip_ids returns error and message with invalid origin/destination combo" do
      params = %{
        "origin" => "Boat-Hingham",
        "destination" => "Boat-Charlestown",
        "relevant_days" => "weekday",
        "trips" => ["Boat-F1-Boat-Hingham-13:00:00-weekday-1", "Boat-F1-Boat-Hingham-15:00:00-weekday-1"],
        "return_trips" => ["Boat-F1-Boat-Long-14:00:00-weekday-0", "Boat-F1-Boat-Long-16:30:00-weekday-0"],
        "trip_type" => "round_trip"
      }
      {:error, _} = FerryMapper.populate_trip_options(params)
    end
  end

  describe "trip_schedule_info_map" do
    @test_date Calendar.Date.from_ordinal!(2017, 226)

    test "maps schedule info between two stations on weekday" do
      use_cassette "trip_schedule_info_weekday_ferry", custom: true, clear_mock: true, match_requests_on: [:query] do
        trip_schedule_info_map = FerryMapper.trip_schedule_info_map("Boat-Charlestown", "Boat-Long", :weekday, @test_date)
        assert Enum.all?(trip_schedule_info_map, &match?({{"Boat-Charlestown", _}, %DateTime{}}, &1) || match?({{"Boat-Long", _}, %DateTime{}}, &1))
      end
    end

    test "maps schedule info between two stations on saturday" do
      use_cassette "trip_schedule_info_saturday_ferry", custom: true, clear_mock: true, match_requests_on: [:query] do
        trip_schedule_info_map = FerryMapper.trip_schedule_info_map("Boat-Charlestown", "Boat-Long", :saturday, Calendar.Date.from_ordinal!(2017, 231))
        assert %{
          {"Boat-Charlestown", "Boat-F4-Boat-Charlestown-12:15:00-weekend-1"} => _,
          {"Boat-Charlestown", "Boat-F4-Boat-Long-11:30:00-weekend-0"} => _,
          {"Boat-Long", "Boat-F4-Boat-Long-11:30:00-weekend-0"} => _,
          {"Boat-Charlestown", "Boat-F4-Boat-Charlestown-13:45:00-weekend-1"} => _,
          {"Boat-Long", "Boat-F4-Boat-Charlestown-13:45:00-weekend-1"} => _,
        } = trip_schedule_info_map
      end
    end
  end

  describe "build_subscription_transaction" do
    @round_trip_params %{
      "origin" => "Boat-Long",
      "destination" => "Boat-Hingham",
      "trips" => ["Boat-F1-Boat-Long-18:05:00-weekday-0", "Boat-F1-Boat-Long-21:10:00-weekday-0"],
      "return_trips" => ["Boat-F1-Boat-Hingham-21:00:00-weekday-1"],
      "relevant_days" => ["weekday"],
      "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
      "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
      "return_start" => DateTime.from_naive!(~N[2017-07-20 18:00:00], "Etc/UTC"),
      "return_end" => DateTime.from_naive!(~N[2017-07-20 20:00:00], "Etc/UTC"),
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }

    test "it builds a multi struct to persist subscriptions and informed_entities" do
      user = insert(:user)
      {:ok, subscription_infos} = FerryMapper.map_subscriptions(@round_trip_params)
      multi = FerryMapper.build_subscription_transaction(subscription_infos, user, user.id)
      result = Ecto.Multi.to_list(multi)

      assert {{:subscription, 0}, {:run, function1}} = List.first(result)
      assert {{:new_informed_entity, 0, 0}, {:run, _}} = Enum.at(result, 1)
      assert {{:subscription, 1}, {:run, function2}} = Enum.find(result, &match?({{:subscription, 1}, {:run, _}}, &1))
      assert {{:new_informed_entity, 1, 0}, {:run, _}} = Enum.find(result, &match?({{:new_informed_entity, 1, 0}, {:run, _}}, &1))

      {:ok, %{model: subscription1}} = function1.(nil)
      {:ok, %{model: subscription2}} = function2.(nil)
      assert subscription1.id != nil
      assert subscription2.id != nil
    end
  end

  describe "build_update_subscription_transaction" do
    test "it builds a multi struct to update subscription" do
      user = insert(:user)
      subscription =
        subscription_factory()
        |> Map.put(:informed_entities, ferry_subscription_entities())
        |> ferry_subscription()
        |> Map.merge(%{user: user, relevant_days: [:weekday]})
        |> insert()

      params = %{
        "alert_priority_type" => :high,
        "end_time" => DateTime.from_naive!(~N[2017-07-20 11:15:00], "Etc/UTC"),
        "start_time" => DateTime.from_naive!(~N[2017-07-20 11:25:00], "Etc/UTC"),
        "trips" => ["Boat-F4-Boat-Charlestown-11:15:00-weekday-1"]
      }

      multi = FerryMapper.build_update_subscription_transaction(subscription, params, user.id)

      assert [
        {{:new_informed_entity, 0}, {:run, function1}},
        {{:remove_old, 0}, {:run, function2}},
        {{:remove_old, 1}, {:run, function3}},
        {{:subscription}, {:run, function4}}
      ] = Ecto.Multi.to_list(multi)
      assert {:ok, %{model: informed_entity1, version: %{event: "insert"}}} = function1.(nil)
      assert informed_entity1.subscription_id == subscription.id
      assert informed_entity1.activities == InformedEntity.default_entity_activities()
      assert {:ok, %{model: _informed_entity2, version: %{event: "delete"}}} = function2.(nil)
      assert {:ok, %{model: _informed_entity3, version: %{event: "delete"}}} = function3.(nil)
      assert {:ok, %{model: updated_subscription, version: %{event: "update"}}} = function4.(nil)
      assert updated_subscription.id == subscription.id
    end
  end
end
