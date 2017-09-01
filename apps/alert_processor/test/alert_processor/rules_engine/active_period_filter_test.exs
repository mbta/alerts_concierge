defmodule AlertProcessor.ActivePeriodFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{ActivePeriodFilter, Model}
  alias Model.{Alert}
  import AlertProcessor.Factory

  defp datetime_from_native(dt) do
    {:ok, datetime} = DateTime.from_naive(dt, "Etc/UTC")
    datetime
  end

  setup_all do
    alert1 = %Alert{
      active_period: [
        %{start: datetime_from_native(~N[2017-04-26 09:00:00]), end: datetime_from_native(~N[2017-04-26 19:00:00])}
      ]
    }

    alert2 = %Alert{
      active_period: [
        %{start: datetime_from_native(~N[2017-04-26 15:00:00]), end: datetime_from_native(~N[2017-04-26 17:00:00])}
      ]
    }

    alert3 = %Alert{
      active_period: [
        %{start: datetime_from_native(~N[2017-04-26 07:00:00]), end: datetime_from_native(~N[2017-04-26 09:00:00])}
      ]
    }

    alert4 = %Alert{
      active_period: [
        %{start: datetime_from_native(~N[2017-04-26 09:00:00]), end: datetime_from_native(~N[2017-04-26 19:00:00])},
        %{start: datetime_from_native(~N[2017-04-29 07:00:00]), end: datetime_from_native(~N[2017-04-29 09:00:00])}
      ]
    }

    alert5 = %Alert{
      active_period: [
        %{start: datetime_from_native(~N[2017-04-26 13:00:00]), end: datetime_from_native(~N[2017-04-27 02:00:00])}
      ]
    }

    alert6 = %Alert{
      active_period: [
        %{start: datetime_from_native(~N[2017-04-28 19:00:00]), end: datetime_from_native(~N[2017-05-01 04:00:00])}
      ]
    }

    alert7 = %Alert{
      active_period: [
        %{start: datetime_from_native(~N[2017-04-26 09:00:00]), end: nil}
      ]
    }

    alert8 = %Alert{
      active_period: [
        %{start: datetime_from_native(~N[2017-04-26 09:00:00]), end: datetime_from_native(~N[2017-04-26 19:00:00])},
        %{start: datetime_from_native(~N[2017-04-27 09:00:00]), end: datetime_from_native(~N[2017-04-27 19:00:00])}
      ]
    }

    {:ok, alert1: alert1, alert2: alert2, alert3: alert3, alert4: alert4, alert5: alert5, alert6: alert6, alert7: alert7, alert8: alert8}
  end

  describe "active period with end date" do
    test "matches if subscription timeframe falls completely between active period", %{alert1: alert1} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [subscription] ==
        ActivePeriodFilter.filter([subscription, sunday_subscription], alert: alert1)
    end

    test "matches if active period falls completely between subscription timeframe", %{alert2: alert2} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [subscription] == ActivePeriodFilter.filter([subscription, sunday_subscription], alert: alert2)
    end

    test "does not match if active period is completely outside of subscription timeframe", %{alert3: alert3} do
      subscription = :subscription |> build() |> sunday_subscription |> insert
      weekday_subscription = :subscription |> build() |> weekday_subscription |> insert

      assert [] == ActivePeriodFilter.filter([subscription, weekday_subscription], alert: alert3)
    end

    test "matches if one active period matches subscription timeframe and one does not", %{alert4: alert4} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [subscription] == ActivePeriodFilter.filter([subscription, sunday_subscription], alert: alert4)
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

      assert [subscription] ==
        ActivePeriodFilter.filter([subscription], alert: alert8)
    end
  end

  describe "active period without end date" do
    test "it matches weekday subscription", %{alert7: alert7} do
      weekday_subscription = :subscription |> build() |> weekday_subscription |> insert
      saturday_subscription = :subscription |> build() |> saturday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert

      assert [weekday_subscription, saturday_subscription, sunday_subscription] ==
        ActivePeriodFilter.filter([weekday_subscription, saturday_subscription, sunday_subscription], alert: alert7)
    end
  end
end
