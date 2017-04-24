defmodule MbtaServer.AlertProcessor.InformedEntityFilterTest do
  use MbtaServer.DataCase
  alias MbtaServer.AlertProcessor
  alias AlertProcessor.{InformedEntityFilter, Model}
  alias Model.{Alert, InformedEntity, Subscription}
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

  defp generate_query(subscription_ids) do
    Ecto.Query.from(s in Subscription, where: s.id in ^subscription_ids)
  end

  defp execute_query(query) do
    Repo.all(from q in subquery(query), select: q.id)
  end

  setup do
    user1 = insert(:user)
    user2 = insert(:user)
    user3 = insert(:user)
    sub1 = insert(:subscription, user: user1)
    sub2 = insert(:subscription, user: user2)
    sub3 = insert(:subscription, user: user3)
    sub4 = insert(:subscription, user: user1)
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: sub1.id}) |> insert
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: sub2.id}) |> insert
    InformedEntity |> struct(@ie4) |> Map.merge(%{subscription_id: sub3.id}) |> insert
    InformedEntity |> struct(@ie2) |> Map.merge(%{subscription_id: sub4.id}) |> insert

    {:ok, sub1: sub1, sub2: sub2, sub3: sub3, sub4: sub4, user1: user1, user2: user2, all_subscription_ids: [sub1.id, sub2.id, sub3.id, sub4.id] }
  end

  test "filter returns :ok empty list if subscription id list passed is empty" do
    assert {:ok, query, @alert1} = InformedEntityFilter.filter({:ok, generate_query([]), @alert1})
    assert [] == execute_query(query)
  end

  test "returns subscription id if informed entity matches subscription", %{sub4: sub4, all_subscription_ids: all_subscription_ids} do
    assert {:ok, query, @alert2} = InformedEntityFilter.filter({:ok, generate_query(all_subscription_ids), @alert2})
    assert [sub4.id] == execute_query(query)
  end

  test "does not return subscription id if subscription not included in previous ids list", %{sub2: sub2} do
    assert {:ok, query, @alert1} = InformedEntityFilter.filter({:ok, generate_query([sub2.id]), @alert1})
    assert [sub2.id] == execute_query(query)
  end

  test "returns multiple subscriptions for same user if both match the alert", %{sub1: sub1, sub4: sub4} do
    {:ok, query, @alert1} = InformedEntityFilter.filter({:ok, generate_query([sub1.id, sub4.id]), @alert1})
    subscription_ids = execute_query(query)
    assert MapSet.new(subscription_ids) == MapSet.new([sub1.id, sub4.id])
  end

  test "does not return subscriptions that only partially match alert informed entity", %{sub3: sub3, all_subscription_ids: all_subscription_ids} do
    assert {:ok, query, @alert4} = InformedEntityFilter.filter({:ok, generate_query(all_subscription_ids), @alert4})
    assert [sub3.id] == execute_query(query)
  end

  test "returns empty list if no matches", %{all_subscription_ids: all_subscription_ids} do
    assert {:ok, query, @alert3} = InformedEntityFilter.filter({:ok, generate_query(all_subscription_ids), @alert3})
    assert [] == execute_query(query)
  end
end
