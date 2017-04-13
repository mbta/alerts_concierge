defmodule MbtaServer.AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """
  alias MbtaServer.User

  @type t :: %__MODULE__{
    user_id: String.t
  }

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "subscriptions" do
    belongs_to :user, User, type: :binary_id

    timestamps()
  end
end
