defmodule MbtaServer.AlertProcessor.SeverityFilter do
  @moduledoc """
  Filter users based on severity determined by a combination of
  severity provided in the alert and effect name.
  """

  import Ecto.Query
  alias MbtaServer.AlertProcessor.{Model.Alert, Model.Subscription}

  @doc """
  filter/1 takes a tuple including a subquery which represents the
  remaining subscriptions to be considered and
  an alert and returns the now remaining subscriptions to be considered
  in the form of an ecto queryable
  which have a matching subscription based on severity and
  an alert to pass through to the next filter.
  """
  @spec filter({:ok, Ecto.Queryable.t, Alert.t}) :: {:ok, Ecto.Queryable.t, Alert.t}
  def filter({:ok, previous_query, %Alert{} = alert}) do
    alert_severity_value = Alert.severity_value(alert)
    query = from s in previous_query,
      where: s.alert_priority_type == "low" and ^(alert_severity_value >= Subscription.severity_value(:low)),
      or_where: s.alert_priority_type == "medium" and ^(alert_severity_value >= Subscription.severity_value(:medium)),
      or_where: s.alert_priority_type == "high" and ^(alert_severity_value >= Subscription.severity_value(:high))

    {:ok, query, alert}
  end
end
