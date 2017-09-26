defmodule AlertProcessor.DigestBuilderTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.{DigestBuilder, Model}
  alias Model.{Alert, Digest, DigestDateGroup, InformedEntity}
  alias Calendar.DateTime, as: DT

  @ddg %DigestDateGroup{}

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

  @digest_interval 604_800

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

    digests = DigestBuilder.build_digests({[@alert1, @alert2], @ddg}, @digest_interval)
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

    digests = DigestBuilder.build_digests({[@alert2], @ddg}, @digest_interval)
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

    digests = DigestBuilder.build_digests({[@alert1, @alert1, @alert2], @ddg}, @digest_interval)
    expected = [%Digest{user: user1, alerts: [@alert1], digest_date_group: @ddg},
                %Digest{user: user2, alerts: [@alert2, @alert1], digest_date_group: @ddg}]

    assert digests == expected
  end

  test "build_digest/1 builds digests for users whose vacations end less than one week from now" do
    now = DateTime.utc_now()
    yesterday = DT.subtract!(now, 86_400)
    six_days_from_now = DT.add!(now, 518_400)
    two_weeks_from_now = DT.add!(now, 1_209_600)
    short_vacation_user = insert(:user,
      vacation_start: yesterday,
      vacation_end: six_days_from_now
    )

    long_vacation_user = insert(:user,
      vacation_start: yesterday,
      vacation_end: two_weeks_from_now
    )

    sub1 = insert(:subscription, user: short_vacation_user)
    sub2 = insert(:subscription, user: long_vacation_user)
    InformedEntity
    |> struct(@ie1)
    |> Map.merge(%{subscription_id: sub1.id})
    |> insert
    InformedEntity
    |> struct(@ie2)
    |> Map.merge(%{subscription_id: sub2.id})
    |> insert

    digests = DigestBuilder.build_digests({[@alert1, @alert2], @ddg}, @digest_interval)
    assert digests == [%Digest{user: short_vacation_user, alerts: [@alert1], digest_date_group: @ddg}]
  end
end
