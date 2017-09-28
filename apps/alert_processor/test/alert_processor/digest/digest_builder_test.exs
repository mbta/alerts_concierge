defmodule AlertProcessor.DigestBuilderTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.{DigestBuilder, Model, Repo}
  alias Model.{Alert, Digest, DigestDateGroup, InformedEntity}
  alias Calendar.DateTime, as: DT

  @ddg %DigestDateGroup{}

  @ie1 %InformedEntity{
    route: "16",
    route_type: 3,
    activities: InformedEntity.default_entity_activities()
  }

  @ie2 %InformedEntity{
    route: "8",
    route_type: 3,
    activities: InformedEntity.default_entity_activities()
  }

  @facility_ie %InformedEntity{
    facility_type: :escalator,
    stop: "place-nqncy",
    activities: InformedEntity.default_entity_activities()
  }

  @alert1 %Alert{
    id: "1",
    header: "test1",
    severity: :severe,
    informed_entities: [
      @ie1,
      @ie2
    ],
    active_period: []
  }

  @alert2 %Alert{
    id: "2",
    header: "test2",
    severity: :minor,
    informed_entities: [
      @ie2
    ],
    active_period: []
  }

  @alert3 %Alert{
    id: "3",
    header: "test3",
    severity: :extreme,
    informed_entities: [
      @ie1
    ],
    active_period: []
  }

  @facility_alert %Alert{
    id: "4",
    header: "test4",
    severity: :moderate,
    informed_entities: [
      @facility_ie
    ],
    active_period: []
  }

  @digest_interval 604_800

  setup_all do
    {:ok, _} = Application.ensure_all_started(:alert_processor)
    :ok
  end

  test "build_digests/1 returns all alerts for each user based on informed entity, including minor severity" do
    user1 = insert(:user)
    user2 = insert(:user)
    sub1 = insert(:subscription, user: user1)
    sub2 = insert(:subscription, user: user2)
    @ie1
    |> Map.merge(%{subscription_id: sub1.id})
    |> insert
    @ie2
    |> Map.merge(%{subscription_id: sub2.id})
    |> insert

    digests = DigestBuilder.build_digests({[@alert1, @alert2], @ddg}, @digest_interval)
    expected = [%Digest{user: user1, alerts: [@alert1], digest_date_group: @ddg},
                %Digest{user: user2, alerts: [@alert2, @alert1], digest_date_group: @ddg}]

    assert digests == expected
  end

  test "build_digest/1 does not return duplicate alerts for each user based on informed entity" do
    user1 = insert(:user)
    user2 = insert(:user)
    sub1 = insert(:subscription, user: user1)
    sub2 = insert(:subscription, user: user2)
    @ie1
    |> Map.merge(%{subscription_id: sub1.id})
    |> insert
    @ie2
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
    @ie1
    |> Map.merge(%{subscription_id: sub1.id})
    |> insert
    @ie2
    |> Map.merge(%{subscription_id: sub2.id})
    |> insert

    digests = DigestBuilder.build_digests({[@alert1, @alert2], @ddg}, @digest_interval)
    assert digests == [%Digest{user: short_vacation_user, alerts: [@alert1], digest_date_group: @ddg}]
  end

  test "build_digest/1 returns all alerts of :extreme severity, regardless of entities" do
    user = insert(:user)
    sub =
      :subscription
      |> insert(user: user)
      |> Repo.preload(:informed_entities)

    digests = DigestBuilder.build_digests({[@alert3], @ddg}, @digest_interval)
    expected = [%Digest{user: user, alerts: [@alert3], digest_date_group: @ddg}]
    assert sub.informed_entities == []
    assert digests == expected
  end

  test "build_digest/1 returns all subs with matching facilities" do
    user = insert(:user)
    sub = insert(:subscription, user: user)

    @facility_ie
    |> Map.merge(%{subscription_id: sub.id})
    |> insert()

    digests = DigestBuilder.build_digests({[@facility_alert], @ddg}, @digest_interval)
    expected = [%Digest{user: user, alerts: [@facility_alert], digest_date_group: @ddg}]
    assert digests == expected
  end

  test "build_digests/1 returns all subs with the same route, >= :moderate severity" do
    user = insert(:user)
    minor_sub = insert(:subscription, user: user, alert_priority_type: :low)
    moderate_sub = insert(:subscription, user: user, alert_priority_type: :medium)

    %InformedEntity{route_type: 0, route: "Red", direction_id: 0}
    |> Map.merge(%{subscription_id: minor_sub.id})
    |> insert()

    %InformedEntity{route_type: 0, route: "Red", direction_id: 0}
    |> Map.merge(%{subscription_id: moderate_sub.id})
    |> insert()

    alert1 = %Alert{
      id: "4",
      header: "test",
      severity: :minor,
      informed_entities: [
        %InformedEntity{
          route_type: 0,
          route: "Red"
        }
      ],
      active_period: []
    }

    alert2 = %Alert{
      id: "5",
      header: "test",
      severity: :moderate,
      informed_entities: [
        %InformedEntity{
          route_type: 0,
          route: "Red"
        }
      ],
      active_period: []
    }

    digests = DigestBuilder.build_digests({[alert1, alert2], @ddg}, @digest_interval)
    expected = [%Digest{user: user, alerts: [alert2], digest_date_group: @ddg}]
    assert digests == expected
  end

  test "build_digests/1 does not return subs that match alerts with minor severity that are currently active" do
    user = insert(:user)
    sub = insert(:subscription, user: user)

    previous_date = DT.from_erl!({{1017, 06, 27}, {2, 30, 0}}, "America/New_York")
    future_date = DT.from_erl!({{3017, 06, 27}, {2, 30, 0}}, "America/New_York")

    @ie1
    |> Map.merge(%{subscription_id: sub.id})
    |> insert

    alert = %Alert{
      id: "6",
      header: "test",
      severity: :minor,
      informed_entities: [@ie1],
      active_period: [%{
        start: previous_date,
        end: future_date
      }]
    }

    digests = DigestBuilder.build_digests({[@alert1, alert], @ddg}, @digest_interval)
    expected = [%Digest{user: user, alerts: [@alert1], digest_date_group: @ddg}]
    assert digests == expected
  end
end
