defmodule AlertProcessor.Model.Digest do
  @moduledoc """
  Representation of Digest data
  """
  alias AlertProcessor.Model
  alias Model.{Alert, DigestDateGroup, User}
  defstruct [:user, :alerts, :digest_date_group]

  @type t :: %__MODULE__{
    user: User.t,
    alerts: [Alert.t],
    digest_date_group: DigestDateGroup.t
  }
end
