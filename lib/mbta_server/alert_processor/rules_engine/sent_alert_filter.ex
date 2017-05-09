defmodule MbtaServer.AlertProcessor.SentAlertFilter do
  @moduledoc """
  Filter users to receive alert based on having previously received alert
  """

  alias MbtaServer.{AlertProcessor, User}
  alias AlertProcessor.Model.{Alert, Subscription}
  import Ecto.Query

  @doc """
  Takes a single alert and returns a ecto queryable representing
  the subscription ids for users that have not received any notifications
  for the alert
  Note: We will use updated_at in lieu of last_push_notification until the API supports that field
  """
  @spec filter(Alert.t) :: {:ok, Ecto.Queryable.t, Alert.t}
  def filter(%Alert{id: alert_id, updated_at: last_push_notification} = alert) do
    query = from s in Subscription,
      join: u in User,
      on: s.user_id == u.id,
      where: fragment(
        "? not in (select n.user_id from notifications n where n.status = 'sent' and n.alert_id = ? and n.last_push_notification = ?)",
        u.id,
        ^alert_id,
        ^last_push_notification
      ),
      distinct: true

    {:ok, query, alert}
  end
end
