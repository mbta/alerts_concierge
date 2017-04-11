defmodule MbtaServer.AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias MbtaServer.AlertProcessor.{Messager, Model.Alert, Model.AlertMessage}

  @type alert :: Alert.t

  @doc """
  process_alert/1 receives an alert and applies relevant filters to send alerts
  to the correct users based on the alert.
  """
  @spec process_alert(alert, MbtaServer.User.t | nil) :: {:ok, map} | {:error, map} | {:error, String.t}
  def process_alert(alert, user \\ test_user()) do
    %{email: email, phone_number: phone_number} = user
    message = %AlertMessage{message: alert.header, email: email, phone_number: phone_number}
    Messager.send_alert_message(message)
  end

  @spec test_user :: %MbtaServer.User{}
  defp test_user do
    import Ecto.Query
    MbtaServer.Repo.one(from x in MbtaServer.User, order_by: [asc: x.id], limit: 1)
  end
end
