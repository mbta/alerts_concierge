defmodule MbtaServer.AlertProcessor.SeverityFilter do
  @moduledoc """
  Filter users based on severity determined by a combination of
  severity provided in the alert and effect name.
  """

  import Ecto.Query
  alias MbtaServer.Repo
  alias MbtaServer.AlertProcessor.{Model.Alert, Model.Subscription}

  @doc """
  filter/1 takes a tuple of the remaining subscriptions to be considered and
  an alert and returns the now remaining subscriptions to be considered
  which have a matching subscription based on severity and
  an alert to pass through to the next filter. Otherwise the flow is
  shortcircuited if the user id list provided is missing or empty.
  """
  @spec filter({:ok, [Subscription.id], Alert.t}) :: {:ok, [Subscription.id], Alert.t}
  def filter({:ok, [], %Alert{} = alert}), do: {:ok, [], alert}
  def filter({:ok, previous_subscription_ids, %Alert{} = alert}) do
    subscriptions = Repo.all(
      from s in Subscription,
      join: ie in assoc(s, :informed_entities),
      preload: [:informed_entities],
      where: s.id in ^previous_subscription_ids
    )

    subscription_ids = Enum.filter_map(subscriptions, &send_alert?(&1, alert), & &1.id)

    {:ok, subscription_ids, alert}
  end

  @spec send_alert?(Subscription.t, Alert.t) :: boolean
  defp send_alert?(subscription, alert) do
    case Alert.severity_value(alert) do
      nil -> false
      alert_severity_value -> alert_severity_value >= Subscription.severity_value(subscription)
    end
  end
end
