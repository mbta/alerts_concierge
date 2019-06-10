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
  @spec filter([Subscription.t()], Keyword.t()) :: [Subscription.t()]
  def filter(subscriptions, alert: alert) do
    do_filter(subscriptions, alert)
  end

  defp do_filter(_, %Alert{active_period: nil}), do: []

  defp do_filter(subscriptions, alert) do
    active_period_timeframe_maps = Alert.timeframe_maps(alert)

    {admins, non_admins} = Enum.split_with(subscriptions, & &1.is_admin)

    Enum.reduce(non_admins, admins, fn sub, acc ->
      sub_map = Subscription.timeframe_map(sub)

      if Enum.any?(active_period_timeframe_maps, &TimeFrameComparison.match?(&1, sub_map)) do
        [sub | acc]
      else
        acc
      end
    end)
  end
end
