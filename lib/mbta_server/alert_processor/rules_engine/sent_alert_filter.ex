defmodule MbtaServer.AlertProcessor.SentAlertFilter do
  @moduledoc """
  Filter users to receive alert based on having previously received alert
  """

  alias MbtaServer.{AlertProcessor, User}
  alias AlertProcessor.Model.{Alert, Notification, Subscription}
  import Ecto.Query

  @doc """
  Takes a single alert and returns a list of subscription ids for users
  that have not received any notifications for the alert
  """
  @spec filter(Alert.t) :: {:ok, Ecto.Queryable.t, Alert.t}
  def filter(%Alert{id: id} = alert) do
    query = from s in Subscription,
      join: u in User,
      left_join: n in Notification,
      on: n.user_id == u.id,
      where: n.alert_id != ^id,
      or_where: is_nil(n.user_id),
      or_where: n.status != "sent",
      distinct: true

    {:ok, query, alert}
  end
end
