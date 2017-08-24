defmodule AlertProcessor.InformedEntityFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{InformedEntityFilter, Model}
  alias Model.{Alert, InformedEntity, Subscription}
  import AlertProcessor.Factory

  @ie1 %{
    route: "16",
    route_type: 3
  }

  @ie2 %{
    route: "8",
    route_type: 3
  }

  @ie3 %{
    route: "1",
    route_type: 3
  }

  @ie4 %{
    route: "16",
    route_type: 3,
    stop: "123"
  }

  @ie5 %{
    stop: "place-pktrm",
    facility: :escalator
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
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: sub1.id}) |> insert
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: sub2.id}) |> insert
    InformedEntity |> struct(@ie4) |> Map.merge(%{subscription_id: sub3.id}) |> insert
    InformedEntity |> struct(@ie2) |> Map.merge(%{subscription_id: sub4.id}) |> insert
    InformedEntity |> struct(@ie5) |> Map.merge(%{subscription_id: sub5.id}) |> insert

    [sub1, sub2, sub3, sub4, sub5] = Subscription
      |> Repo.all()
      |> Repo.preload(:informed_entities)
      |> Repo.preload(:user)

    {:ok, sub1: sub1, sub2: sub2, sub3: sub3, sub4: sub4, sub5: sub5,
     user1: user1, user2: user2, all_subscriptions: [sub1, sub2, sub3, sub4, sub5]}
  end

  test "filter returns :ok empty list if subscription list passed is empty" do
    assert {:ok, [], @alert1} == InformedEntityFilter.filter({:ok, [], @alert1})
  end

  test "returns subscription id if informed entity matches subscription", %{sub4: sub4, all_subscriptions: all_subscriptions} do
    assert {:ok, [sub4], @alert2} == InformedEntityFilter.filter({:ok, all_subscriptions, @alert2})
  end

  test "does not return subscription id if subscription not included in previous ids list", %{sub2: sub2} do
    assert {:ok, [sub2], @alert1} == InformedEntityFilter.filter({:ok, [sub2], @alert1})
  end

  test "returns multiple subscriptions for same user if both match the alert", %{sub1: sub1, sub4: sub4} do
    assert {:ok, [sub1, sub4], @alert1} == InformedEntityFilter.filter({:ok, [sub1, sub4], @alert1})
  end

  test "does not return subscriptions that only partially match alert informed entity", %{sub3: sub3, all_subscriptions: all_subscriptions} do
    assert {:ok, [sub3], @alert4} == InformedEntityFilter.filter({:ok, all_subscriptions, @alert4})
  end

  test "returns empty list if no matches", %{all_subscriptions: all_subscriptions} do
    assert {:ok, [], @alert3} == InformedEntityFilter.filter({:ok, all_subscriptions, @alert3})
  end

  test "matches facility alerts", %{sub5: sub5, all_subscriptions: all_subscriptions} do
    assert {:ok, [sub5], @alert5} == InformedEntityFilter.filter({:ok, all_subscriptions, @alert5})
  end

  test "matches admin mode subscription", %{sub1: sub1, sub2: sub2} do
    user = insert(:user, role: "application_administration")
    admin_sub =
      :admin_subscription
      |> insert(type: :bus, user: user)
      |> Repo.preload(:user)
      |> Repo.preload(:informed_entities)
    assert {:ok, [admin_sub], @alert4} == InformedEntityFilter.filter({:ok, [admin_sub, sub1, sub2], @alert4})
  end

  test "doesnt match non application admin mode subscription", %{sub1: sub1, sub2: sub2} do
    user = insert(:user, role: "customer_support")
    admin_sub =
      :admin_subscription
      |> insert(type: :bus, user: user)
      |> Repo.preload(:user)
      |> Repo.preload(:informed_entities)
    assert {:ok, [], @alert4} == InformedEntityFilter.filter({:ok, [admin_sub, sub1, sub2], @alert4})
  end
end
