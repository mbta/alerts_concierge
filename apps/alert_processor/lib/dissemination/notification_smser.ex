defmodule AlertProcessor.NotificationSmser do
  @moduledoc """
  Module to handle sending sms messages to AWS SNS.
  Retrieves module constant from config to allow using mock for tests.
  """

  alias AlertProcessor.Model.Notification

  @doc "notification_sms/2 takes the message to be sent and the phone number to send the sms to."
  @spec notification_sms(Notification.t, String.t) :: ExAws.Operation.Query.t
  def notification_sms(%Notification{header: header}, phone_number) do
    ExAws.SNS.publish(header, [phone_number: "+1#{phone_number}"])
  end
end
