defmodule AlertProcessor.ActivePeriodFilterTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  alias AlertProcessor.{ActivePeriodFilter, Model}
  alias Model.{Alert}
  import AlertProcessor.Factory

  setup_all do
    alert1 = %Alert{
      active_period: [
        %{
          start: ~U[2017-04-26 09:00:00Z],
          end: ~U[2017-04-26 19:00:00Z]
        }
      ]
    }

    alert2 = %Alert{
      active_period: [
        %{
          start: ~U[2017-04-26 11:00:00Z],
          end: ~U[2017-04-26 13:00:00Z]
        }
      ]
    }

    alert3 = %Alert{
      active_period: [
        %{
          start: ~U[2017-04-26 07:00:00Z],
          end: ~U[2017-04-26 09:00:00Z]
        }
      ]
    }

    alert4 = %Alert{
      active_period: [
        %{
          start: ~U[2017-04-26 09:00:00Z],
          end: ~U[2017-04-26 19:00:00Z]
        },
        %{
          start: ~U[2017-04-29 07:00:00Z],
          end: ~U[2017-04-29 09:00:00Z]
        }
      ]
    }

    alert5 = %Alert{
      active_period: [
        %{
          start: ~U[2017-04-26 13:00:00Z],
          end: ~U[2017-04-27 02:00:00Z]
        }
      ]
    }

    alert6 = %Alert{
      active_period: [
        %{
          start: ~U[2017-04-28 19:00:00Z],
          end: ~U[2017-05-01 04:00:00Z]
        }
      ]
    }

    alert7 = %Alert{
      active_period: [
        %{start: ~U[2017-04-26 09:00:00Z], end: nil}
      ]
    }

    alert8 = %Alert{
      active_period: [
        %{
          start: ~U[2017-04-26 09:00:00Z],
          end: ~U[2017-04-26 19:00:00Z]
        },
        %{
          start: ~U[2017-04-27 09:00:00Z],
          end: ~U[2017-04-27 19:00:00Z]
        }
      ]
    }

    {:ok,
     alert1: alert1,
     alert2: alert2,
     alert3: alert3,
     alert4: alert4,
     alert5: alert5,
     alert6: alert6,
     alert7: alert7,
     alert8: alert8}
  end

  describe "active period with end date" do
    test "matches if subscription timeframe falls completely between active period", %{
      alert1: alert1
    } do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [subscription] ==
               ActivePeriodFilter.filter([subscription, sunday_subscription], alert: alert1)
    end

    test "matches if active period falls completely between subscription timeframe", %{
      alert2: alert2
    } do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [subscription] ==
               ActivePeriodFilter.filter([subscription, sunday_subscription], alert: alert2)
    end

    test "does not match if active period is completely outside of subscription timeframe", %{
      alert3: alert3
    } do
      subscription = :subscription |> build() |> sunday_subscription |> insert
      weekday_subscription = :subscription |> build() |> weekday_subscription |> insert

      assert [] == ActivePeriodFilter.filter([subscription, weekday_subscription], alert: alert3)
    end

    test "matches if one active period matches subscription timeframe and one does not", %{
      alert4: alert4
    } do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [subscription] ==
               ActivePeriodFilter.filter([subscription, sunday_subscription], alert: alert4)
    end

    test "matches multiday active period", %{alert5: alert5} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [subscription] ==
               ActivePeriodFilter.filter([subscription, sunday_subscription], alert: alert5)
    end

    test "matches multiday active period more than 1 day difference", %{alert6: alert6} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [sunday_subscription] ==
               ActivePeriodFilter.filter([subscription, sunday_subscription], alert: alert6)
    end

    test "matches mutliple active periods but only returns subscription once", %{alert8: alert8} do
      user = insert(:user)
      subscription = :subscription |> build(user: user) |> weekday_subscription |> insert

      assert [subscription] == ActivePeriodFilter.filter([subscription], alert: alert8)
    end

    test "matches for for individual weekday (e.g. Monday)" do
      alert = %Alert{
        active_period: [
          %{
            # Monday
            start: ~U[2018-03-26 09:00:00Z],
            end: ~U[2018-03-26 19:00:00Z]
          }
        ]
      }

      subscription = insert(:subscription, relevant_days: [:monday])

      subscriptions = ActivePeriodFilter.filter([subscription], alert: alert)

      assert subscriptions == [subscription]
    end

    test "does not match for for individual weekday (e.g. Tuesday)" do
      alert = %Alert{
        active_period: [
          %{
            # Monday
            start: ~U[2018-03-26 09:00:00Z],
            end: ~U[2018-03-26 19:00:00Z]
          }
        ]
      }

      subscription = insert(:subscription, relevant_days: [:tuesday])

      subscriptions = ActivePeriodFilter.filter([subscription], alert: alert)

      assert subscriptions == []
    end
  end

  describe "active period without end date" do
    test "it matches weekday subscription", %{alert7: alert7} do
      weekday_subscription = :subscription |> build() |> weekday_subscription() |> insert()
      saturday_subscription = :subscription |> build() |> saturday_subscription() |> insert()
      sunday_subscription = :subscription |> build() |> sunday_subscription() |> insert()

      assert [sunday_subscription, saturday_subscription, weekday_subscription] ==
               ActivePeriodFilter.filter(
                 [weekday_subscription, saturday_subscription, sunday_subscription],
                 alert: alert7
               )
    end
  end

  describe "with alert with nil 'active_period'" do
    test "does not match" do
      alert = %Alert{active_period: nil}
      subscription = :subscription |> build() |> weekday_subscription()

      assert [] == ActivePeriodFilter.filter([subscription], alert: alert)
    end
  end
end
