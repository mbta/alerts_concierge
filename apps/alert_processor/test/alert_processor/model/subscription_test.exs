defmodule AlertProcessor.Model.SubscriptionTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Model.{Alert, InformedEntity, Route, Subscription, User}
  alias AlertProcessor.ServiceInfoCache
  alias Ecto.Multi

  @base_attrs %{
    relevant_days: [:weekday],
    start_time: ~T[12:00:00],
    end_time: ~T[18:00:00],
    travel_start_time: ~T[14:00:00],
    travel_end_time: ~T[16:00:00]
  }

  setup do
    user = insert(:user)
    valid_attrs = Map.put(@base_attrs, :user_id, user.id)

    {:ok, user: user, valid_attrs: valid_attrs}
  end

  test "create_changeset/2 with valid parameters", %{valid_attrs: valid_attrs} do
    changeset = Subscription.create_changeset(%Subscription{}, valid_attrs)
    assert changeset.valid?
  end

  test "create_changeset/2 permits travel_start_time and travel_end_time", %{
    valid_attrs: valid_attrs
  } do
    changeset = Subscription.create_changeset(%Subscription{}, valid_attrs)
    assert Map.has_key?(changeset.changes, :travel_start_time)
    assert Map.has_key?(changeset.changes, :travel_end_time)
  end

  test "create_changeset/2 requires a user_id", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :user_id)
    changeset = Subscription.create_changeset(%Subscription{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 validates relevant days", %{valid_attrs: valid_attrs} do
    attrs = Map.put(valid_attrs, :relevant_days, [:garbage])
    changeset = Subscription.create_changeset(%Subscription{}, attrs)

    refute changeset.valid?
  end

  test "update_changeset/2 with valid parameters", %{valid_attrs: valid_attrs} do
    changeset = Subscription.update_changeset(%Subscription{}, valid_attrs)
    assert changeset.valid?
  end

  test "update_changeset/2 does not allow user_id", %{valid_attrs: valid_attrs} do
    changeset = Subscription.update_changeset(%Subscription{}, valid_attrs)
    refute Map.has_key?(changeset.changes, :user_id)
  end

  describe "timeframe map" do
    test "maps timeframe for weekday" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[18:00:00],
        relevant_days: [:weekday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 43_200, end: 64_800},
               tuesday: %{start: 43_200, end: 64_800},
               wednesday: %{start: 43_200, end: 64_800},
               thursday: %{start: 43_200, end: 64_800},
               friday: %{start: 43_200, end: 64_800}
             } == timeframe_map
    end

    test "maps timeframe for monday" do
      subscription = %Subscription{
        start_time: ~T[10:00:00],
        end_time: ~T[16:00:00],
        relevant_days: [:monday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 36_000, end: 57_600}
             } == timeframe_map
    end

    test "maps timeframe for saturday" do
      subscription = %Subscription{
        start_time: ~T[10:00:00],
        end_time: ~T[16:00:00],
        relevant_days: [:saturday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               saturday: %{start: 36_000, end: 57_600}
             } == timeframe_map
    end

    test "maps timeframe for sunday" do
      subscription = %Subscription{
        start_time: ~T[08:00:00],
        end_time: ~T[14:00:00],
        relevant_days: [:sunday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               sunday: %{start: 28_800, end: 50_400}
             } == timeframe_map
    end

    test "maps timeframe for multiple relevant days" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[18:00:00],
        relevant_days: [:weekday, :saturday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 43_200, end: 64_800},
               tuesday: %{start: 43_200, end: 64_800},
               wednesday: %{start: 43_200, end: 64_800},
               thursday: %{start: 43_200, end: 64_800},
               friday: %{start: 43_200, end: 64_800},
               saturday: %{start: 43_200, end: 64_800}
             } == timeframe_map
    end

    test "maps timeframe to next timeframe for late night service" do
      subscription = %Subscription{
        start_time: ~T[01:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:weekday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               tuesday: %{start: 3600, end: 14_400},
               wednesday: %{start: 3600, end: 14_400},
               thursday: %{start: 3600, end: 14_400},
               friday: %{start: 3600, end: 14_400},
               saturday: %{start: 3600, end: 14_400}
             } == timeframe_map
    end

    test "maps timeframe to next timeframe for late night service for saturday" do
      subscription = %Subscription{
        start_time: ~T[01:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:saturday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               sunday: %{start: 3600, end: 14_400}
             } == timeframe_map
    end

    test "maps timeframe to next timeframe for late night service for sunday" do
      subscription = %Subscription{
        start_time: ~T[01:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:sunday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 3600, end: 14_400}
             } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for weekday" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:weekday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 43_200, end: 86_399},
               tuesday: %{start: 43_200, end: 14_400},
               wednesday: %{start: 43_200, end: 14_400},
               thursday: %{start: 43_200, end: 14_400},
               friday: %{start: 43_200, end: 14_400},
               saturday: %{start: 0, end: 14_400}
             } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for saturday" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:saturday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               saturday: %{start: 43_200, end: 86_399},
               sunday: %{start: 0, end: 14_400}
             } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for sunday" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:sunday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               sunday: %{start: 43_200, end: 86_399},
               monday: %{start: 0, end: 14_400}
             } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for multiple relevant days" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:weekday, :saturday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 43_200, end: 86_399},
               tuesday: %{start: 43_200, end: 14_400},
               wednesday: %{start: 43_200, end: 14_400},
               thursday: %{start: 43_200, end: 14_400},
               friday: %{start: 43_200, end: 14_400},
               saturday: %{start: 43_200, end: 14_400},
               sunday: %{start: 0, end: 14_400}
             } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for all relevant days" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:weekday, :saturday, :sunday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 43_200, end: 14_400},
               tuesday: %{start: 43_200, end: 14_400},
               wednesday: %{start: 43_200, end: 14_400},
               thursday: %{start: 43_200, end: 14_400},
               friday: %{start: 43_200, end: 14_400},
               saturday: %{start: 43_200, end: 14_400},
               sunday: %{start: 43_200, end: 14_400}
             } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for all relevant days different order" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:saturday, :weekday, :sunday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 43_200, end: 14_400},
               tuesday: %{start: 43_200, end: 14_400},
               wednesday: %{start: 43_200, end: 14_400},
               thursday: %{start: 43_200, end: 14_400},
               friday: %{start: 43_200, end: 14_400},
               saturday: %{start: 43_200, end: 14_400},
               sunday: %{start: 43_200, end: 14_400}
             } == timeframe_map
    end

    test "maps early segment for timeframes that go over midnight for all relevant days different order still doesnt matter" do
      subscription = %Subscription{
        start_time: ~T[12:00:00],
        end_time: ~T[04:00:00],
        relevant_days: [:sunday, :saturday, :weekday]
      }

      timeframe_map = Subscription.timeframe_map(subscription)

      assert %{
               monday: %{start: 43_200, end: 14_400},
               tuesday: %{start: 43_200, end: 14_400},
               wednesday: %{start: 43_200, end: 14_400},
               thursday: %{start: 43_200, end: 14_400},
               friday: %{start: 43_200, end: 14_400},
               saturday: %{start: 43_200, end: 14_400},
               sunday: %{start: 43_200, end: 14_400}
             } == timeframe_map
    end
  end

  describe "set_versioned_subscription/1" do
    @params %{
      "routes" => ["16 - 0"],
      "relevant_days" => ["weekday", "saturday"],
      "departure_start" => ~T[12:00:00],
      "departure_end" => ~T[14:00:00],
      "return_start" => ~T[18:00:00],
      "return_end" => ~T[20:00:00],
      "trip_type" => "one_way"
    }

    test "creates subscription and informed entities from Ecto.Multi" do
      user = insert(:user)
      {:ok, [info | _]} = map_subscription(@params)
      multi = build_subscription_transaction([info], user, user.id)
      Subscription.set_versioned_subscription(multi)

      assert [sub | _] = Subscription |> Repo.all() |> Repo.preload(:informed_entities)
      refute Enum.empty?(sub.informed_entities)
    end

    test "associates versions of informed entities with version of subscription" do
      user = insert(:user)
      {:ok, [info | _]} = map_subscription(@params)
      multi = build_subscription_transaction([info], user, user.id)
      Subscription.set_versioned_subscription(multi)

      [sub | _] = Subscription |> Repo.all() |> Repo.preload(:informed_entities)
      sub_version = PaperTrail.get_version(sub)

      informed_entity_version_ids =
        Enum.map(sub.informed_entities, fn ie ->
          PaperTrail.get_version(ie).id
        end)

      assert MapSet.new(sub_version.meta["informed_entity_version_ids"]) ==
               MapSet.new(informed_entity_version_ids)
    end

    test "creates round_trip subscription and informed entities from Ecto.Multi" do
      user = insert(:user)

      {:ok, [info1, info2 | _]} = map_subscription(Map.put(@params, "trip_type", "round_trip"))

      multi = build_subscription_transaction([info1, info2], user, user.id)
      Subscription.set_versioned_subscription(multi)

      assert [sub1, sub2 | _] = Subscription |> Repo.all() |> Repo.preload(:informed_entities)
      refute Enum.empty?(sub1.informed_entities)
      refute Enum.empty?(sub2.informed_entities)
    end

    test "associates versions of informed entities with version of round_trip subscription" do
      user = insert(:user)

      {:ok, [info1, info2 | _]} = map_subscription(Map.put(@params, "trip_type", "round_trip"))

      multi = build_subscription_transaction([info1, info2], user, user.id)
      Subscription.set_versioned_subscription(multi)

      [sub1, sub2 | _] = Subscription |> Repo.all() |> Repo.preload(:informed_entities)

      sub_version1 = PaperTrail.get_version(sub1)

      informed_entity_version_ids =
        Enum.map(sub1.informed_entities, fn ie ->
          PaperTrail.get_version(ie).id
        end)

      assert MapSet.new(sub_version1.meta["informed_entity_version_ids"]) ==
               MapSet.new(informed_entity_version_ids)

      sub_version2 = PaperTrail.get_version(sub2)

      informed_entity_version_ids =
        Enum.map(sub2.informed_entities, fn ie ->
          PaperTrail.get_version(ie).id
        end)

      assert MapSet.new(sub_version2.meta["informed_entity_version_ids"]) ==
               MapSet.new(informed_entity_version_ids)
    end
  end

  describe "delete_subscription" do
    test "deletes subscription" do
      user = insert(:user)

      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.merge(%{user_id: user.id})
        |> insert()

      assert {:ok, subscription} = Subscription.delete_subscription(subscription, user.id)
      assert nil == Repo.get(Subscription, subscription.id)
    end

    test "deletes associated informed entities" do
      user = insert(:user)
      subscription = insert(:subscription, %{user_id: user.id})
      insert(:informed_entity, %{subscription_id: subscription.id})
      informed_entities = Repo.all(InformedEntity)
      assert length(informed_entities) > 0
      Subscription.delete_subscription(subscription, user.id)
      assert Repo.all(InformedEntity) == []
    end
  end

  describe "relevant_days_string" do
    test "converts weekday subscription relevant days into human friendly iodata" do
      subscription = :subscription |> build() |> weekday_subscription()
      relevant_days_string = Subscription.relevant_days_string(subscription)
      assert IO.iodata_to_binary(relevant_days_string) == "Weekdays"
    end

    test "converts weekday, saturday subscription relevant days into human friendly iodata" do
      subscription = :subscription |> build() |> saturday_subscription() |> weekday_subscription()
      relevant_days_string = Subscription.relevant_days_string(subscription)
      assert IO.iodata_to_binary(relevant_days_string) == "Weekdays, Saturdays"
    end

    test "converts weekday, saturday, sunday subscription relevant days into human friendly iodata" do
      subscription =
        :subscription
        |> build()
        |> sunday_subscription()
        |> saturday_subscription()
        |> weekday_subscription()

      relevant_days_string = Subscription.relevant_days_string(subscription)
      assert IO.iodata_to_binary(relevant_days_string) == "Weekdays, Saturdays, Sundays"
    end
  end

  describe "route_count/1" do
    test "returns the number of route entities in a subscription" do
      user = build(:user)

      {:ok, subscription} =
        :subscription
        |> build(user: user)
        |> weekday_subscription()
        |> bus_subscription()
        |> Repo.preload(:informed_entities)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:informed_entities, bus_subscription_entities())
        |> Repo.insert()

      assert 1 == Subscription.route_count(subscription)
    end

    test "returns the number of route entities in a subscription for multiple" do
      user = build(:user)

      {:ok, subscription} =
        :subscription
        |> build(user: user)
        |> weekday_subscription()
        |> bus_subscription()
        |> Repo.preload(:informed_entities)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(
          :informed_entities,
          bus_subscription_entities() ++ bus_subscription_entities("87")
        )
        |> Repo.insert()

      assert 2 == Subscription.route_count(subscription)
    end

    test "treats same route in opposite direction as separate route" do
      user = build(:user)

      {:ok, subscription} =
        :subscription
        |> build(user: user)
        |> weekday_subscription()
        |> bus_subscription()
        |> Repo.preload(:informed_entities)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(
          :informed_entities,
          Enum.uniq(
            bus_subscription_entities("87", :inbound) ++
              bus_subscription_entities("87", :outbound)
          )
        )
        |> Repo.insert()

      assert 2 == Subscription.route_count(subscription)
    end
  end

  describe "add_latlong_to_subscription/3" do
    test "with stop values" do
      subscription =
        Subscription.add_latlong_to_subscription(%Subscription{}, "place-alfcl", "place-dwnxg")

      assert Float.round(subscription.destination_lat, 6) == 42.355518
      assert Float.round(subscription.destination_long, 6) == -71.060225
      assert Float.round(subscription.origin_lat, 6) == 42.395428
      assert Float.round(subscription.origin_long, 6) == -71.142483
    end

    test "without stop values" do
      subscription = Subscription.add_latlong_to_subscription(%Subscription{}, "", "")
      assert subscription == %Subscription{}
    end
  end

  describe "all_active_for_alert/1" do
    @only_route_type_alert %Alert{
      id: "101",
      informed_entities: [%InformedEntity{route_type: 0, route: nil}]
    }

    @only_stop_alert %Alert{
      id: "102",
      informed_entities: [%InformedEntity{stop: "place-nqnce"}]
    }

    @route_type_and_red_line_alert %Alert{
      id: "103",
      informed_entities: [%InformedEntity{route_type: 0, route: "Red"}]
    }

    @route_type_route_and_stop_alert %Alert{
      id: "104",
      informed_entities: [
        %InformedEntity{route_type: 2}
      ]
    }

    @wildcard_alert %Alert{
      id: "105",
      informed_entities: [%InformedEntity{route_type: nil, route: nil, stop: nil}]
    }

    test "only selects active, matches as subscription" do
      user = insert(:user)
      # Active subscription
      insert(:subscription, user: user)
      # Paused subscription
      insert(:subscription, user: user, paused: true)

      alert = @wildcard_alert

      assert [%Subscription{paused: false}] = Subscription.all_active_for_alert(alert)
    end

    test "preloads the user" do
      user = insert(:user)
      insert(:subscription, user: user)

      alert = @wildcard_alert

      [subscrption] = Subscription.all_active_for_alert(alert)
      assert subscrption.user == user
    end

    test "subscriptions filtered by route, only selects red line subscription" do
      user = insert(:user)
      insert(:subscription, user: user, route: "Red")
      insert(:subscription, user: user, route: "Orange")

      alert = @route_type_and_red_line_alert

      assert [%Subscription{route: "Red"}] = Subscription.all_active_for_alert(alert)
    end

    test "subscriptions filtered by route_type, only selects route_type 2 subscription" do
      user = insert(:user)
      insert(:subscription, user: user, route_type: 0, route: "Red")
      insert(:subscription, user: user, route_type: 2, route: "CR-Fairmount")

      alert = @route_type_route_and_stop_alert

      assert [%Subscription{route_type: 2}] = Subscription.all_active_for_alert(alert)
    end

    test "subscriptions filtered by stop, only selects origin or destination place-nqnce" do
      user = insert(:user)
      insert(:subscription, user: user, route_type: 0)
      insert(:subscription, user: user, route_type: 2)
      insert(:subscription, user: user, origin: "place-nqnce")
      insert(:subscription, user: user, destination: "place-nqnce")

      alert = @only_stop_alert

      [subscription1, subscription2] = Subscription.all_active_for_alert(alert)

      assert subscription1.origin == "place-nqnce"
      assert subscription2.destination == "place-nqnce"
    end

    test "subscriptions filtered by route_type, no match to alert" do
      user = insert(:user)
      insert(:subscription, user: user, origin: "place-nqnce")
      insert(:subscription, user: user, destination: "place-nqnce")

      alert = @only_route_type_alert

      assert [] = Subscription.all_active_for_alert(alert)
    end

    test "rejects subscriptions for which a notification has been sent to that user for this alert" do
      user = insert(:user)
      subscription = insert(:subscription, user: user, origin: "place-nqnce")

      # Sent notification for the subscription
      notification =
        insert(:notification, %{
          alert_id: @only_stop_alert.id,
          user_id: user.id,
          status: :sent
        })

      insert(:notification_subscription, %{
        subscription: subscription,
        notification: notification
      })

      alert = @only_stop_alert

      assert [] = Subscription.all_active_for_alert(alert)
    end
  end

  test "paused_count returns the number of paused subscriptions" do
    user = insert(:user)
    insert(:subscription, user: user, route: "Red", paused: true)
    insert(:subscription, user: user, route: "Orange")
    insert(:subscription, user: user, route: "Blue", paused: true)

    assert Subscription.paused_count() == 2
  end

  defp map_subscription(%{"routes" => routes} = params) do
    params = Map.delete(params, "routes")

    subscription_infos =
      Enum.flat_map(routes, fn route_and_direction ->
        route_id = route_and_direction |> String.split_at(-4) |> elem(0)
        direction = route_and_direction |> String.split_at(-1) |> elem(1) |> String.to_integer()
        {:ok, route} = ServiceInfoCache.get_route(route_id)

        params =
          params
          |> Map.put("route", route_id)
          |> Map.put("direction", direction)
          |> Map.put("origin", nil)
          |> Map.put("destination", nil)
          |> Map.put("return_trip", false)

        params
        |> create_subscriptions()
        |> map_entities(params, route)
      end)

    {:ok, subscription_infos}
  end

  defp create_subscriptions(%{"origin" => origin, "destination" => destination} = params) do
    return_params = %{
      params
      | "destination" => origin,
        "origin" => destination,
        "departure_start" => params["return_start"],
        "departure_end" => params["return_end"],
        "direction" => flip_direction(params["direction"]),
        "return_trip" => true
    }

    [do_create_subscription(params), do_create_subscription(return_params)]
  end

  defp do_create_subscription(params) do
    %Subscription{
      start_time: params["departure_start"],
      end_time: params["departure_end"],
      relevant_days: Enum.map(params["relevant_days"], &String.to_existing_atom/1),
      origin: params["origin"],
      destination: params["destination"],
      route: params["route"],
      direction_id: params["direction"],
      return_trip: params["return_trip"],
      type: :bus
    }
  end

  defp flip_direction(0), do: 1
  defp flip_direction(1), do: 0
  defp flip_direction(_), do: nil

  defp map_entities(subscriptions, params, route) do
    subscriptions
    |> map_route_type(route)
    |> map_route(params, route)
  end

  defp map_route_type(subscriptions, %Route{route_type: type}) do
    route_type_entities = [
      %InformedEntity{route_type: type, activities: InformedEntity.default_entity_activities()}
    ]

    Enum.map(subscriptions, fn subscription ->
      {subscription, route_type_entities}
    end)
  end

  defp map_route([{sub1, ie1}, {sub2, ie2}], _params, %Route{route_id: route, route_type: type}) do
    route_entities_1 = [
      %InformedEntity{
        route: route,
        route_type: type,
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route: route,
        route_type: type,
        direction_id: sub1.direction_id,
        activities: InformedEntity.default_entity_activities()
      }
    ]

    route_entities_2 = [
      %InformedEntity{
        route: route,
        route_type: type,
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route: route,
        route_type: type,
        direction_id: sub2.direction_id,
        activities: InformedEntity.default_entity_activities()
      }
    ]

    [{sub1, ie1 ++ route_entities_1}, {sub2, ie2 ++ route_entities_2}]
  end

  defp build_subscription_transaction(subscriptions, user, originator) do
    subscriptions
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {{sub, ies}, index}, acc ->
      uuid = Ecto.UUID.generate()

      sub_to_insert =
        sub
        |> Map.merge(%{
          id: uuid,
          user_id: user.id
        })
        |> Subscription.create_changeset()

      acc =
        acc
        |> Multi.run({:subscription, index}, fn _ ->
          PaperTrail.insert(
            sub_to_insert,
            originator: User.wrap_id(originator),
            meta: %{owner: user.id}
          )
        end)

      ies
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {ie, i}, accumulator ->
        Multi.run(accumulator, {:new_informed_entity, index, i}, fn _ ->
          ie_to_insert =
            ie
            |> Map.merge(%{
              subscription_id: uuid
            })

          PaperTrail.insert(
            ie_to_insert,
            originator: User.wrap_id(originator),
            meta: %{owner: user.id}
          )
        end)
      end)
    end)
  end
end
