defmodule AlertProcessor.ActivePeriodFilter do
  @moduledoc """
  Filter subscriptions based on matching an active period in an alert
  """
  alias AlertProcessor.{Model, TimeFrameComparison}
  alias Model.{Alert, Subscription}

  @doc """
  filter/1 takes a tuple including a subquery which represents the remaining
  subscriptions to be considered and an alert and returns the now remaining
  subscriptions to be considered in the form of an ecto queryable which have
  been matched based on the active period(s) in the alert.
  """
  @spec filter([Subscription.t], Keyword.t) :: [Subscription.t]
  def filter(subscriptions, [alert: alert]) do
    SystemMetrics.Tracer.trace(fn() ->
      do_filter(subscriptions, alert)
    end, "active_period_filter")
  end

  defp do_filter(subscriptions, alert) do
    subscription_timeframe_maps = for x <- subscriptions, into: %{} do
      {x.id, Subscription.timeframe_map(x)}
    end
    active_period_timeframe_maps = Alert.timeframe_maps(alert)

    for sub <- subscriptions,
      active_period_timeframe_map <- active_period_timeframe_maps,
      TimeFrameComparison.match?(active_period_timeframe_map,  Map.get(subscription_timeframe_maps, sub.id)) do
      sub
    end
  end
end
