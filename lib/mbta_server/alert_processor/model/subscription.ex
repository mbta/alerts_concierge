defmodule MbtaServer.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """

  @type t :: %__MODULE__{
    alert_types: [String.t],
    end_time: DateTime.t,
    priority: String.t,
    start_time: DateTime.t,
    travel_days: [String.t],
    user_id: String.t
  }

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "subscriptions" do
    belongs_to :user, User, type: :binary_id

    field :alert_types, {:array, :string}
    field :end_time, :utc_datetime
    field :priority, :string
    field :start_time, :utc_datetime
    field :travel_days, {:array, :string}

    timestamps()
  end
end
