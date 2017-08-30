defmodule AlertProcessor.SeverityFilter do
  @moduledoc """
  Filter users based on severity determined by a combination of
  severity provided in the alert and effect name.
  """
  alias AlertProcessor.{Model.Alert, Model.Subscription}

  @doc """
  filter/1 takes a tuple including a subquery which represents the
  remaining subscriptions to be considered and
  an alert and returns the now remaining subscriptions to be considered
  in the form of an ecto queryable
  which have a matching subscription based on severity and
  an alert to pass through to the next filter.
  """
  @spec filter([Subscription.t], Keyword.t) :: [Subscription.t]
  def filter(subscriptions, [alert: alert]) do
    SystemMetrics.Tracer.trace(fn() ->
      do_filter(subscriptions, alert)
    end, "severity_filter")
  end

  defp do_filter(subscriptions, alert) do
    alert_severity_value = Alert.severity_value(alert)

    Enum.filter(subscriptions, fn(sub) ->
      Subscription.severity_value(sub.alert_priority_type) <= alert_severity_value
    end)
  end
end
