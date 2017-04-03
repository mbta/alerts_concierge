defmodule MbtaServer.AlertProcessor.Model.AlertMessage do

  @moduledoc """
  An individual message generated from an alert
  """
  defstruct [:alert_id, :user_id, :send_after, :message, :header]

  @type t :: %__MODULE__{
    alert_id: String.t,
    user_id: String.t,
    send_after: Date.t,
    message: String.t,
    header: String.t,
  }
end
