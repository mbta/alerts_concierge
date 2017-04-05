defmodule MbtaServer.AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias MbtaServer.AlertProcessor.Messager

  @type alert :: %{
    header: String.t
  }

  @doc """
  process_alert/1 receives an alert and applies relevant filters to send alerts
  to the correct users based on the alert.
  """
  @spec process_alert(alert, MbtaServer.User.t | nil) :: {:ok, Map} | {:error, Map} | {:error, String.t}
  def process_alert(alert, user \\ test_user()) do
    %{email: email, phone_number: phone_number} = user
    Messager.send_alert_message({alert[:header], email, phone_number})
  end

  @spec test_user :: %MbtaServer.User{}
  defp test_user do
    import Ecto.Query
    MbtaServer.Repo.one(from x in MbtaServer.User, order_by: [asc: x.id], limit: 1)
  end
end
