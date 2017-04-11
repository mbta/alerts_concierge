defmodule MbtaServer.AlertProcessor.NotificationSmser do
  @moduledoc """
  Module to handle sending sms messages to AWS SNS.
  Retrieves module constant from config to allow using mock for tests.
  """
  @ex_aws_sns Application.get_env(:mbta_server, :ex_aws_sns)

  @doc "notification_sms/2 takes the message to be sent and the phone number to send the sms to."
  @spec notification_sms(String.t, String.t) :: ExAws.Operation.Query.t
  def notification_sms(notification, phone_number) do
    @ex_aws_sns.publish(notification, [{:phone_number, phone_number}])
  end
end
