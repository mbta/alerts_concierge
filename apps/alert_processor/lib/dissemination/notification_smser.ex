defmodule AlertProcessor.NotificationSmser do
  @moduledoc """
  Module to handle sending sms messages to AWS SNS.
  Retrieves module constant from config to allow using mock for tests.
  """

  alias AlertProcessor.Model.Notification

  @doc "notification_sms/1 takes the notification to be sent via sms."
  @spec notification_sms(Notification.t) :: ExAws.Operation.Query.t
  def notification_sms(%Notification{header: header, type: type, phone_number: phone_number}) do
    header
    |> add_type_prefix(type)
    |> ExAws.SNS.publish([phone_number: "+1#{phone_number}"])
  end

  defp add_type_prefix(text, :all_clear) do
    "All clear (re: #{text})"
  end

  defp add_type_prefix(text, _), do: text
end
