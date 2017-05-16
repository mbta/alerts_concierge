defmodule MbtaServer.AlertProcessor.ActivePeriodFilter do
  @moduledoc """
  Filter subscriptions based on matching an active period in an alert
  """

  import Ecto.Query
  alias MbtaServer.AlertProcessor.{Model, Repo, TimeFrameComparison}
  alias Model.{Alert, Subscription}

  @doc """
  filter/1 takes a tuple including a subquery which represents the remaining
  subscriptions to be considered and an alert and returns the now remaining
  subscriptions to be considered in the form of an ecto queryable which have
  been matched based on the active period(s) in the alert.
  """
  @spec filter({:ok, Ecto.Queryable.t, Alert.t}) :: {:ok, Ecto.Queryable.t, Alert.t}
  def filter({:ok, previous_query, %Alert{} = alert}) do
    subscriptions = Repo.all(from s in subquery(previous_query))
    subscription_timeframe_maps = for x <- subscriptions, into: %{} do
      {x.id, Subscription.timeframe_map(x)}
    end
    active_period_timeframe_maps = Alert.timeframe_maps(alert)

    all_matched_sub_ids = for sub <- subscriptions,
      active_period_timeframe_map <- active_period_timeframe_maps,
      TimeFrameComparison.match?(active_period_timeframe_map,  Map.get(subscription_timeframe_maps, sub.id)) do
      sub.id
    end

    query = from s in Subscription, where: s.id in ^Enum.uniq(all_matched_sub_ids)

    {:ok, query, alert}
  end
end
