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
  @spec filter({:ok, Ecto.Queryable.t, Alert.t}) :: {:ok, Ecto.Queryable.t, Alert.t}
  def filter({:ok, subscriptions, %Alert{} = alert}) do
    alert_severity_value = Alert.severity_value(alert)

    matching_subscriptions = Enum.filter(subscriptions, fn(sub) ->
      Subscription.severity_value(sub.alert_priority_type) <= alert_severity_value
    end)

    {:ok, matching_subscriptions, alert}
  end
end
