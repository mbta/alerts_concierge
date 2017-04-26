defmodule MbtaServer.AlertProcessor.ActivePeriodFilterTest do
  use MbtaServer.DataCase
  alias MbtaServer.{AlertProcessor, QueryHelper}
  alias AlertProcessor.{ActivePeriodFilter, Model}
  alias Model.{Alert, Subscription}
  import MbtaServer.Factory

  defp generate_datetime(timestamp) do
    {:ok, datetime, _} = DateTime.from_iso8601(timestamp)
    datetime
  end

  setup do
    alert1 = %Alert{
      active_period: [
        %{start: generate_datetime("2017-04-26T09:00:00-04:00"), end: generate_datetime("2017-04-26T19:00:00-04:00")}
      ]
    }

    alert2 = %Alert{
      active_period: [
        %{start: generate_datetime("2017-04-26T12:00:00-04:00"), end: generate_datetime("2017-04-26T13:00:00-04:00")}
      ]
    }

    alert3 = %Alert{
      active_period: [
        %{start: generate_datetime("2017-04-26T07:00:00-04:00"), end: generate_datetime("2017-04-26T09:00:00-04:00")}
      ]
    }

    alert4 = %Alert{
      active_period: [
        %{start: generate_datetime("2017-04-26T09:00:00-04:00"), end: generate_datetime("2017-04-26T19:00:00-04:00")},
        %{start: generate_datetime("2017-04-29T07:00:00-04:00"), end: generate_datetime("2017-04-29T09:00:00-04:00")}
      ]
    }

    alert5 = %Alert{
      active_period: [
        %{start: generate_datetime("2017-04-26T13:00:00-04:00"), end: generate_datetime("2017-04-27T02:00:00-04:00")}
      ]
    }

    alert6 = %Alert{
      active_period: [
        %{start: generate_datetime("2017-04-28T19:00:00-04:00"), end: generate_datetime("2017-05-01T04:00:00-04:00")}
      ]
    }

    alert7 = %Alert{
      active_period: [
        %{start: generate_datetime("2017-04-26T09:00:00-04:00"), end: nil}
      ]
    }

    {:ok, alert1: alert1, alert2: alert2, alert3: alert3, alert4: alert4, alert5: alert5, alert6: alert6, alert7: alert7}
  end

  describe "active period with end date" do
    test "matches if subscription timeframe falls completely between active period", %{alert1: alert1} do
      subscription = build(:subscription) |> weekday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert1} = ActivePeriodFilter.filter({:ok, previous_query, alert1})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "matches if active period falls completely between subscription timeframe", %{alert2: alert2} do
      subscription = build(:subscription) |> weekday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert2} = ActivePeriodFilter.filter({:ok, previous_query, alert2})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "does not match if active period is completely outside of subscription timeframe", %{alert3: alert3} do
      subscription = build(:subscription) |> sunday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert3} = ActivePeriodFilter.filter({:ok, previous_query, alert3})
      assert [] == QueryHelper.execute_query(query)
    end

    test "matches if one active period matches subscription timeframe and one does not", %{alert4: alert4} do
      subscription = build(:subscription) |> weekday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert4} = ActivePeriodFilter.filter({:ok, previous_query, alert4})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "matches multiday active period", %{alert5: alert5} do
      subscription = build(:subscription) |> weekday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert5} = ActivePeriodFilter.filter({:ok, previous_query, alert5})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "matches multiday active period more than 1 day difference", %{alert6: alert6} do
      subscription = build(:subscription) |> weekday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert6} = ActivePeriodFilter.filter({:ok, previous_query, alert6})
      assert [] == QueryHelper.execute_query(query)
    end
  end

  describe "active period without end date" do
    test "it matches weekday subscription", %{alert7: alert7} do
      subscription = build(:subscription) |> weekday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert7} = ActivePeriodFilter.filter({:ok, previous_query, alert7})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "it matches sunday subscription", %{alert7: alert7} do
      subscription = build(:subscription) |> sunday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert7} = ActivePeriodFilter.filter({:ok, previous_query, alert7})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "it matches saturday subscription", %{alert7: alert7} do
      subscription = build(:subscription) |> saturday_subscription |> insert
      previous_query = QueryHelper.generate_query(Subscription, [subscription.id])
      assert {:ok, query, ^alert7} = ActivePeriodFilter.filter({:ok, previous_query, alert7})
      assert [subscription.id] == QueryHelper.execute_query(query)
    end
  end
end
