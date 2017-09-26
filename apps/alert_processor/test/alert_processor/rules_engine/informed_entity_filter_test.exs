defmodule AlertProcessor.InformedEntityFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{InformedEntityFilter, Model}
  alias Model.{Alert, InformedEntity, Subscription}
  import AlertProcessor.Factory

  @ie1 %{
    route: "16",
    route_type: 3,
    activities: ["BOARD", "EXIT", "RIDE"]
  }

  @ie2 %{
    route: "8",
    route_type: 3,
    activities: ["BOARD", "EXIT", "RIDE"]
  }

  @ie3 %{
    route: "1",
    route_type: 3,
    activities: ["BOARD", "EXIT", "RIDE"]
  }

  @ie4 %{
    route: "16",
    route_type: 3,
    stop: "123",
    activities: ["BOARD", "EXIT", "RIDE"]
  }

  @ie5 %{
    stop: "place-pktrm",
    facility: :escalator,
    activities: ["USING_ESCALATOR"]
  }

  @ie6 %{
    trip: "775",
    route_type: 2,
    route: "CR-Fairmount",
    activities: ["BOARD", "EXIT", "RIDE"]
  }

  @ie7 %{
    route_type: 2,
    route: "CR-Lowell",
    stop: "Mishawum",
    activities: ["BOARD", "EXIT"]
  }

  @alert1 %Alert{
    id: "1",
    header: "test1",
    informed_entities: [
      @ie1,
      @ie2
    ]
  }

  @alert2 %Alert{
    id: "2",
    header: "test2",
    informed_entities: [
      @ie2
    ]
  }

  @alert3 %Alert{
    id: "3",
    header: "test3",
    informed_entities: [
      @ie3
    ]
  }

  @alert4 %Alert{
    id: "4",
    header: "test4",
    informed_entities: [
      @ie4
    ]
  }

  @alert5 %Alert{
    id: "5",
    header: "test5",
    informed_entities: [
      @ie5
    ]
  }

  @alert6 %Alert{
    id: "6",
    header: "test6",
    informed_entities: [
      @ie6
    ]
  }

  @alert7 %Alert{
    id: "7",
    header: "test7",
    informed_entities: [
      @ie7
    ]
  }

  setup do
    user1 = insert(:user)
    user2 = insert(:user)
    user3 = insert(:user)
    user4 = insert(:user)
    sub1 = insert(:subscription, user: user1)
    sub2 = insert(:subscription, user: user2)
    sub3 = insert(:subscription, user: user3)
    sub4 = insert(:subscription, user: user1)
    sub5 = insert(:subscription, user: user4)
    sub6 = insert(:subscription, user: user1)
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: sub1.id}) |> insert
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: sub2.id}) |> insert
    InformedEntity |> struct(@ie4) |> Map.merge(%{subscription_id: sub3.id}) |> insert
    InformedEntity |> struct(@ie2) |> Map.merge(%{subscription_id: sub4.id}) |> insert
    InformedEntity |> struct(@ie5) |> Map.merge(%{subscription_id: sub5.id}) |> insert
    InformedEntity |> struct(%{trip: "775", subscription_id: sub6.id}) |> insert

    [sub1, sub2, sub3, sub4, sub5, sub6] = Subscription
      |> Repo.all()
      |> Repo.preload(:informed_entities)
      |> Repo.preload(:user)

    {:ok, sub1: sub1, sub2: sub2, sub3: sub3, sub4: sub4, sub5: sub5, sub6: sub6,
     user1: user1, user2: user2, all_subscriptions: [sub1, sub2, sub3, sub4, sub5, sub6]}
  end

  test "filter returns :ok empty list if subscription list passed is empty" do
    assert [] == InformedEntityFilter.filter([], alert: @alert1)
  end

  test "returns subscription id if informed entity matches subscription", %{sub4: sub4, all_subscriptions: all_subscriptions} do
    assert [sub4] == InformedEntityFilter.filter(all_subscriptions, alert: @alert2)
  end

  test "does not return subscription id if subscription not included in previous ids list", %{sub2: sub2} do
    assert [sub2] == InformedEntityFilter.filter([sub2], alert: @alert1)
  end

  test "returns multiple subscriptions for same user if both match the alert", %{sub1: sub1, sub4: sub4} do
    assert [sub1, sub4] == InformedEntityFilter.filter([sub1, sub4], alert: @alert1)
  end

  test "does not return subscriptions that only partially match alert informed entity", %{sub3: sub3, all_subscriptions: all_subscriptions} do
    assert [sub3] == InformedEntityFilter.filter(all_subscriptions, alert: @alert4)
  end

  test "returns empty list if no matches", %{all_subscriptions: all_subscriptions} do
    assert [] == InformedEntityFilter.filter(all_subscriptions, alert: @alert3)
  end

  test "matches facility alerts", %{sub5: sub5, all_subscriptions: all_subscriptions} do
    assert [sub5] == InformedEntityFilter.filter(all_subscriptions, alert: @alert5)
  end

  test "matches admin mode subscription", %{sub1: sub1, sub2: sub2} do
    user = insert(:user, role: "application_administration")
    admin_sub =
      :admin_subscription
      |> insert(type: :bus, user: user)
      |> Repo.preload(:user)
      |> Repo.preload(:informed_entities)
    assert [admin_sub] == InformedEntityFilter.filter([admin_sub, sub1, sub2], alert: @alert4)
  end

  test "doesnt match non application admin mode subscription", %{sub1: sub1, sub2: sub2} do
    user = insert(:user, role: "customer_support")
    admin_sub =
      :admin_subscription
      |> insert(type: :bus, user: user)
      |> Repo.preload(:user)
      |> Repo.preload(:informed_entities)
    assert [] == InformedEntityFilter.filter([admin_sub, sub1, sub2], alert: @alert4)
  end

  test "matches trips", %{sub6: sub6, all_subscriptions: all_subscriptions} do
    assert [sub6] == InformedEntityFilter.filter(all_subscriptions, alert: @alert6)
  end

  test "ignores intermediate stops if activities do not match" do
    user = insert(:user)
    {:ok, subscription} =
      :subscription
      |> build(user: user)
      |> weekday_subscription()
      |> commuter_rail_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, [%InformedEntity{route_type: 2, route: "CR-Lowell", stop: "Mishawum", activities: ["RIDE"]} | commuter_rail_subscription_entities()])
      |> Repo.insert()
    assert [] == InformedEntityFilter.filter([subscription], alert: @alert7)
  end
end
