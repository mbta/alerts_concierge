defmodule AlertProcessor.AlertCourtesyEmail do
  @moduledoc """
  Sends new or updated alerts to a configurable email address.
  """
  @mailer Application.get_env(:alert_processor, :mailer)
  alias AlertProcessor.NotificationBuilder
  alias AlertProcessor.Model.{User, Subscription, SavedAlert, Alert}
  alias AlertProcessor.Helpers.ConfigHelper

  @spec send_courtesy_emails([SavedAlert.t()], [Alert.t()]) :: [map()]
  def send_courtesy_emails([], _), do: []

  def send_courtesy_emails(saved_alerts, parsed_alerts) do
    email_address = ConfigHelper.get_string(:courtesy_email_address)
    user = %User{email: email_address}
    subscription = %Subscription{start_time: ~T[07:00:00]}
    alert_ids = Enum.map(saved_alerts, & &1.alert_id)
    parsed_alerts_to_send = Enum.filter(parsed_alerts, &Enum.member?(alert_ids, &1.id))

    notifications =
      Enum.map(
        parsed_alerts_to_send,
        &NotificationBuilder.build_notification({user, [subscription]}, &1)
      )

    for notification <- notifications do
      {:ok, email} = @mailer.send_notification_email(notification)
      email
    end
  end
end
