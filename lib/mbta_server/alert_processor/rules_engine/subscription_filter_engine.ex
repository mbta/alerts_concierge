defmodule MbtaServer.AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias MbtaServer.{Repo, User}
  alias MbtaServer.AlertProcessor.{Model.Alert, Model.Notification}
  alias MbtaServer.AlertProcessor.{Dispatcher, InformedEntityFilter, SentAlertFilter, SeverityFilter}
  import Ecto.Query

  @doc """
  process_alert/1 receives an alert and applies relevant filters to send alerts
  to the correct users based on the alert.
  """
  @spec process_alert(Alert.t) :: [{:ok, map} | {:error, map} | {:error, String.t}]
  def process_alert(alert) do
    Enum.map(fetch_relevant_users(alert), fn(user) ->
      %{email: email, phone_number: phone_number} = user
      notification = %Notification{message: alert.header, email: email, phone_number: phone_number}
      Dispatcher.send_notification(notification)
    end)
  end

  @spec fetch_relevant_users(Alert.t) :: [User.t]
  defp fetch_relevant_users(alert) do
    {:ok, query, ^alert} =
      alert
      |> SentAlertFilter.filter
      |> InformedEntityFilter.filter
      |> SeverityFilter.filter

    Repo.all(from u in User, join: s in subquery(query), on: s.user_id == u.id, distinct: true)
  end
end
