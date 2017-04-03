defmodule MbtaServer.AlertProcessor.AlertMessageSmser do
  @moduledoc """
  Module to handle sending sms messages to AWS SNS.
  Retrieves module constant from config to allow using mock for tests.
  """
  @ex_aws_sns Application.get_env(:mbta_server, :ex_aws_sns)

  @doc "alert_message_sms/2 takes the message to be sent and the phone number to send the sms to."
  @spec alert_message_sms(String.t, String.t) :: ExAws.Operation.Query.t
  def alert_message_sms(message, phone_number) do
    @ex_aws_sns.publish(message, [{:phone_number, phone_number}])
  end
end
