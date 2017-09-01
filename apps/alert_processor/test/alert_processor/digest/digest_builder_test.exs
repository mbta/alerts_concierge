defmodule AlertProcessor.DigestBuilderTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.{DigestBuilder, Model}
  alias Model.{Alert, Digest, DigestDateGroup, InformedEntity}

  @ddg %DigestDateGroup{}

  @ie1 %{
    route: "16",
    route_type: 3
  }

  @ie2 %{
    route: "8",
    route_type: 3
  }

  @alert1 %Alert{
    id: "1",
    header: "test1",
    severity: :high,
    informed_entities: [
      @ie1,
      @ie2
    ]
  }

  @alert2 %Alert{
    id: "2",
    header: "test2",
    severity: :low,
    informed_entities: [
      @ie2
    ]
  }

  setup_all do
    {:ok, _} = Application.ensure_all_started(:alert_processor)
    :ok
  end

  test "build_digests/1 returns all alerts for each user based on informed entity" do
    user1 = insert(:user)
    user2 = insert(:user)
    sub1 = insert(:subscription, user: user1)
    sub2 = insert(:subscription, user: user2)
    InformedEntity
    |> struct(@ie1)
    |> Map.merge(%{subscription_id: sub1.id})
    |> insert
    InformedEntity
    |> struct(@ie2)
    |> Map.merge(%{subscription_id: sub2.id})
    |> insert

    digests = DigestBuilder.build_digests({[@alert1, @alert2], @ddg})
    expected = [%Digest{user: user1, alerts: [@alert1], digest_date_group: @ddg},
                %Digest{user: user2, alerts: [@alert2, @alert1], digest_date_group: @ddg}]

    assert digests == expected
  end

  test "build_digests/1 does not filter on severity" do
    user = insert(:user)

    sub = insert(:subscription, user: user, alert_priority_type: :medium)
    InformedEntity
    |> struct(@ie2)
    |> Map.merge(%{subscription_id: sub.id})
    |> insert

    digests = DigestBuilder.build_digests({[@alert2], @ddg})
    assert digests == [%Digest{user: user, alerts: [@alert2], digest_date_group: @ddg}]
  end

  test "build_digest/1 does not return duplicate alerts for each user based on informed entity" do
    user1 = insert(:user)
    user2 = insert(:user)
    sub1 = insert(:subscription, user: user1)
    sub2 = insert(:subscription, user: user2)
    InformedEntity
    |> struct(@ie1)
    |> Map.merge(%{subscription_id: sub1.id})
    |> insert
    InformedEntity
    |> struct(@ie2)
    |> Map.merge(%{subscription_id: sub2.id})
    |> insert

    digests = DigestBuilder.build_digests({[@alert1, @alert1, @alert2], @ddg})
    expected = [%Digest{user: user1, alerts: [@alert1], digest_date_group: @ddg},
                %Digest{user: user2, alerts: [@alert2, @alert1], digest_date_group: @ddg}]

    assert digests == expected
  end

  test "build_digest/1 does not build digests for disabled users" do
    active_user = insert(:user)
    disabled_user = insert(:user, encrypted_password: "")

    sub1 = insert(:subscription, user: active_user)
    sub2 = insert(:subscription, user: disabled_user)
    InformedEntity
    |> struct(@ie1)
    |> Map.merge(%{subscription_id: sub1.id})
    |> insert
    InformedEntity
    |> struct(@ie2)
    |> Map.merge(%{subscription_id: sub2.id})
    |> insert

    digests = DigestBuilder.build_digests({[@alert1, @alert2], @ddg})
    assert digests == [%Digest{user: active_user, alerts: [@alert1], digest_date_group: @ddg}]
  end
end
