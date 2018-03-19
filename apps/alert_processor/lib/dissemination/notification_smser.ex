defmodule AlertProcessor.NotificationSmser do
  @moduledoc """
  Module to handle sending sms messages to AWS SNS.
  Retrieves module constant from config to allow using mock for tests.
  """

  alias AlertProcessor.Model.Notification

  @doc "notification_sms/1 takes the notification to be sent via sms."
  @spec notification_sms(Notification.t) :: ExAws.Operation.Query.t
  def notification_sms(%Notification{header: header, closed_timestamp: nil, phone_number: phone_number}) do
    ExAws.SNS.publish(header, [phone_number: "+1#{phone_number}"])
  end
  def notification_sms(%Notification{header: header, phone_number: phone_number}) do
    ExAws.SNS.publish(closed_text(header), [phone_number: "+1#{phone_number}"])
  end

  defp closed_text(text) do
    "All clear (re: #{text})"
  end
end
