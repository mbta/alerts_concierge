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

  setup do
    user1 = insert(:user)
    user2 = insert(:user)
    subscription1 = insert(:subscription, user: user1)
    subscription2 = insert(:subscription, user: user2)
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: subscription1.id}) |> insert
    InformedEntity |> struct(@ie2) |> Map.merge(%{subscription_id: subscription1.id}) |> insert
    InformedEntity |> struct(@ie1) |> Map.merge(%{subscription_id: subscription2.id}) |> insert

    {:ok, user1: user1, user2: user2}
  end

  test "returns user id if informed entity matches subscription", %{user1: user1} do
    assert {:ok, [user1.id]} == InformedEntityFilter.filter(@alert2)
  end

  test "returns one user id even if informed entity matches multiple subscriptions", %{user1: user1, user2: user2} do
    {:ok, user_ids} = InformedEntityFilter.filter(@alert1)
    assert MapSet.new(user_ids) == MapSet.new([user1.id, user2.id])
  end

  test "returns empty list if no matches" do
    assert {:ok, []} == InformedEntityFilter.filter(@alert3)
  end
end
