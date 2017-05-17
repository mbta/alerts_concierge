defmodule AlertProcessor.ActivePeriodFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{ActivePeriodFilter, Model, QueryHelper}
  alias Model.{Alert, Subscription}
  import AlertProcessor.Factory

  defp datetime_from_native(dt) do
    {:ok, datetime} = DateTime.from_naive(dt, "Etc/UTC")
    datetime
  end

  setup do
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

    {:ok, alert1: alert1, alert2: alert2, alert3: alert3, alert4: alert4, alert5: alert5, alert6: alert6, alert7: alert7}
  end

  describe "active period with end date" do
    test "matches if subscription timeframe falls completely between active period", %{alert1: alert1} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id, sunday_subscription.id])
      assert {:ok, query, ^alert1} = ActivePeriodFilter.filter({:ok, previous_query, alert1})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "matches if active period falls completely between subscription timeframe", %{alert2: alert2} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id, sunday_subscription.id])
      assert {:ok, query, ^alert2} = ActivePeriodFilter.filter({:ok, previous_query, alert2})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "does not match if active period is completely outside of subscription timeframe", %{alert3: alert3} do
      subscription = :subscription |> build() |> sunday_subscription |> insert
      weekday_subscription = :subscription |> build() |> weekday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id, weekday_subscription.id])
      assert {:ok, query, ^alert3} = ActivePeriodFilter.filter({:ok, previous_query, alert3})
      assert [] == QueryHelper.execute_query(query)
    end

    test "matches if one active period matches subscription timeframe and one does not", %{alert4: alert4} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id, sunday_subscription.id])
      assert {:ok, query, ^alert4} = ActivePeriodFilter.filter({:ok, previous_query, alert4})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "matches multiday active period", %{alert5: alert5} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id, sunday_subscription.id])
      assert {:ok, query, ^alert5} = ActivePeriodFilter.filter({:ok, previous_query, alert5})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "matches multiday active period more than 1 day difference", %{alert6: alert6} do
      subscription = :subscription |> build() |> weekday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id, sunday_subscription.id])
      assert {:ok, query, ^alert6} = ActivePeriodFilter.filter({:ok, previous_query, alert6})
      assert [sunday_subscription.id] == QueryHelper.execute_query(query)
    end
  end

  describe "active period without end date" do
    test "it matches weekday subscription", %{alert7: alert7} do
      weekday_subscription = :subscription |> build() |> weekday_subscription |> insert
      saturday_subscription = :subscription |> build() |> saturday_subscription |> insert
      sunday_subscription = :subscription |> build() |> sunday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [weekday_subscription.id, saturday_subscription.id, sunday_subscription.id])
      assert {:ok, query, ^alert7} = ActivePeriodFilter.filter({:ok, previous_query, alert7})
      assert MapSet.new([weekday_subscription.id, saturday_subscription.id, sunday_subscription.id]) == MapSet.new(QueryHelper.execute_query(query))
    end
  end
end
