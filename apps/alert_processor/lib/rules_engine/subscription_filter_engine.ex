defmodule AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias AlertProcessor.{Model.Alert, Model.Notification}
  alias AlertProcessor.{ActivePeriodFilter, InformedEntityFilter, Repo, Scheduler, SentAlertFilter, SeverityFilter}
  import Ecto.Query

  @doc """
  process_alert/1 receives an alert and applies relevant filters to send alerts
  to the correct users based on the alert.
  """
  @spec process_alert(Alert.t) :: {:ok, [Notification.t]}
  def process_alert(alert) do
    {:ok, query, ^alert} =
      alert
      |> SentAlertFilter.filter
      |> InformedEntityFilter.filter
      |> SeverityFilter.filter
      |> ActivePeriodFilter.filter

    subscription_ids = Repo.all(from s in subquery(query), distinct: true, select: s.id)
    Scheduler.schedule_notifications({:ok, subscription_ids, alert})
  end
end
