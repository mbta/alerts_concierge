defmodule AlertProcessor.AlertCourtesyEmail do
  @moduledoc """
  Sends new or updated alerts to a configurable email address.
  """
  alias AlertProcessor.NotificationBuilder
  alias AlertProcessor.Dissemination.NotificationSender
  alias AlertProcessor.Model.{User, Subscription, SavedAlert, Alert, Notification}
  alias AlertProcessor.Helpers.ConfigHelper

  @spec send_courtesy_emails([SavedAlert.t()], [Alert.t()]) :: [Notification.t()]
  def send_courtesy_emails([], _), do: []

  def send_courtesy_emails(saved_alerts, parsed_alerts) do
    email_address = ConfigHelper.get_string(:courtesy_email_address)
    user = %User{email: email_address}
    subscription = %Subscription{start_time: ~T[07:00:00]}
    alert_ids = Enum.map(saved_alerts, & &1.alert_id)

    saved_alerts_types =
      Enum.reduce(saved_alerts, %{}, fn saved_alert, accumulator ->
        Map.put(accumulator, saved_alert.alert_id, saved_alert.notification_type)
      end)

    parsed_alerts_to_send = Enum.filter(parsed_alerts, &Enum.member?(alert_ids, &1.id))

    notifications =
      parsed_alerts_to_send
      |> Enum.map(&NotificationBuilder.build_notification({user, [subscription]}, &1))
      |> Enum.map(fn notification ->
        type =
          if notification.alert.closed_timestamp,
            do: :all_clear,
            else: saved_alerts_types[notification.alert.id]

        %{notification | type: type}
      end)
      |> Enum.filter(&filter_out_silent_all_clears(&1))

    if email_address != "" do
      for notification <- notifications do
        NotificationSender.send(notification)
      end
    end

    notifications
  end

  # only remove :all_clear notification where the last_push_notification doesn't match the closed_timestamp
  # this indicated that the notification has been closed but subscribers should not be notified
  defp filter_out_silent_all_clears(%{
         type: :all_clear,
         alert: %{
           last_push_notification: last_push_notification,
           closed_timestamp: closed_timestamp
         }
       })
       when last_push_notification == closed_timestamp,
       do: true

  defp filter_out_silent_all_clears(%{
         type: :all_clear
       }),
       do: false

  defp filter_out_silent_all_clears(_), do: true
end
