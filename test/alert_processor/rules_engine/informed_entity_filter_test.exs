defmodule MbtaServer.AlertProcessor.InformedEntityFilterTest do
  use MbtaServer.DataCase
  alias MbtaServer.AlertProcessor
  alias AlertProcessor.{InformedEntityFilter, Model}
  alias Model.{Alert, InformedEntity}
  import MbtaServer.Factory

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

  setup do
    user1 = insert(:user)
    user2 = insert(:user)
    user3 = insert(:user)
    subscription1 = insert(:subscription, user: user1)
    subscription2 = insert(:subscription, user: user2)
    subscription3 = insert(:subscription, user: user3)
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: subscription1.id}) |> insert
    InformedEntity |> struct(@ie2) |> Map.merge(%{subscription_id: subscription1.id}) |> insert
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: subscription2.id}) |> insert
    InformedEntity |> struct(@ie4) |> Map.merge(%{subscription_id: subscription3.id}) |> insert

    {:ok, user1: user1, user2: user2, user3: user3, all_user_ids: [user1.id, user2.id, user3.id]}
  end

  test "filter returns :ok empty list if user id list past is empty or nil" do
    assert {:ok, [], @alert1} == InformedEntityFilter.filter({:ok, [], @alert1})
    assert {:ok, [], @alert1} == InformedEntityFilter.filter({:ok, nil, @alert1})
  end

  test "returns user id if informed entity matches subscription", %{user1: user1, all_user_ids: all_user_ids} do
    assert {:ok, [user1.id], @alert2} == InformedEntityFilter.filter({:ok, all_user_ids, @alert2})
  end

  test "returns one user id even if informed entity matches multiple subscriptions", %{user1: user1, user2: user2, all_user_ids: all_user_ids} do
    {:ok, user_ids, @alert1} = InformedEntityFilter.filter({:ok, all_user_ids, @alert1})
    assert MapSet.new(user_ids) == MapSet.new([user1.id, user2.id])
  end

  test "does not return user id if not included in previous ids list", %{user2: user2} do
    assert {:ok, [user2.id], @alert1} == InformedEntityFilter.filter({:ok, [user2.id], @alert1})
  end

  test "does not return subscriptions that only partially match alert informed entity", %{user3: user3, all_user_ids: all_user_ids} do
    assert {:ok, [user3.id], @alert4} == InformedEntityFilter.filter({:ok, all_user_ids, @alert4})
  end

  test "returns empty list if no matches", %{all_user_ids: all_user_ids} do
    assert {:ok, [], @alert3} == InformedEntityFilter.filter({:ok, all_user_ids, @alert3})
  end
end
