defmodule AlertProcessor.Dispatcher do
  @moduledoc """
  Module to handle the dissemination of notifications to proper mediums based on user subscriptions.
  """

  @mailer Application.get_env(:alert_processor, :mailer)
  alias AlertProcessor.{Aws.AwsClient, Model.Notification, NotificationSmser}
  alias AlertProcessor.Helpers.DateTimeHelper
  require Logger

  @doc """
  send_notification/1 receives a map of user information and notification to
  delegate to the proper api.
  """
  @spec send_notification(Notification.t()) :: AwsClient.response()
  def send_notification(%Notification{header: nil}) do
    {:error, "no notification"}
  end

  def send_notification(%Notification{email: nil, phone_number: nil}) do
    {:error, "no contact information"}
  end

  def send_notification(%Notification{email: email, phone_number: nil} = notification)
      when not is_nil(email) do
    log_times(notification)
    email = @mailer.send_notification_email(notification)
    {:ok, email}
  end

  def send_notification(
        %Notification{
          id: notification_id,
          phone_number: phone_number,
          header: header,
          closed_timestamp: closed_timestamp,
          alert_id: alert_id,
          user: user
        } = notification
      )
      when not is_nil(phone_number) do
    log_times(notification)

    result =
      notification
      |> NotificationSmser.notification_sms()
      |> AwsClient.request()

    Logger.info(fn ->
      "SMS notification: notification_id=#{notification_id} header=#{header} user_id=#{user.id} alert_id=#{
        alert_id
      } closed_timestamp=#{closed_timestamp} result=#{inspect(result)}"
    end)

    result
  end

  def send_notification(_) do
    {:error, "invalid or missing params"}
  end

  defp log_times(notification, now \\ DateTime.utc_now())
  defp log_times(%{tracking_optimal_time: nil}, _), do: nil
  defp log_times(%{tracking_matched_time: nil}, _), do: nil

  defp log_times(
         %{
           tracking_optimal_time: tracking_optimal_time,
           tracking_matched_time: tracking_matched_time,
           alert: %{last_push_notification: last_push_notification}
         },
         now
       ) do
    tracking_sent_time = DateTimeHelper.datetime_to_local(now)

    seconds_until_match = DateTime.diff(tracking_matched_time, tracking_optimal_time)
    seconds_in_sending_queue = DateTime.diff(tracking_sent_time, tracking_matched_time)
    seconds_processing = seconds_until_match + seconds_in_sending_queue
    alert_age_in_seconds = DateTime.diff(now, last_push_notification)

    Logger.info(fn ->
      "notification time, alert_age_in_seconds=#{alert_age_in_seconds} seconds_until_match=#{
        seconds_until_match
      } seconds_in_sending_queue=#{seconds_in_sending_queue} seconds_processing=#{
        seconds_processing
      } time_optimal=#{tracking_optimal_time} time_matched=#{tracking_matched_time} time_sent=#{
        tracking_sent_time
      }"
    end)
  end
end
