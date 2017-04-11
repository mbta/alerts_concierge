defmodule MbtaServer.AlertProcessor.Model.Notification do

  @moduledoc """
  An individual message generated from an alert
  """
  defstruct [:alert_id, :user_id, :send_after, :message, :header, :phone_number, :email]

  @type t :: %__MODULE__{
    alert_id: String.t,
    user_id: String.t,
    send_after: DateTime.t,
    message: String.t,
    header: String.t,
    phone_number: String.t,
    email: String.t
  }
end
