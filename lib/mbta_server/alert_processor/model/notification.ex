defmodule MbtaServer.AlertProcessor.Model.Notification do
  @moduledoc """
  An individual message generated from an alert
  """

  @type t :: %__MODULE__{
    alert_id: String.t,
    user_id: String.t,
    send_after: DateTime.t,
    message: String.t,
    header: String.t,
    phone_number: String.t,
    email: String.t,
    status: atom,
    last_push_notification: DateTime.t
  }

  use Ecto.Schema
  import Ecto.Changeset
  alias MbtaServer.Repo
  alias MbtaServer.AlertProcessor.Model.User

  @spec save(__MODULE__.t, atom) ::
  {:ok, __MODULE__.t} | {:error, Ecto.Changeset.t}
  def save(notification, status) do
    Repo.insert(__MODULE__.create_changeset(%{notification | status: status}))
  end

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "notifications" do
    belongs_to :user, User, type: :binary_id

    field :alert_id, :string
    field :send_after, :utc_datetime
    field :message, :string
    field :header, :string
    field :phone_number, :string
    field :email, :string
    field :status, MbtaServer.AlertProcessor.AtomType
    field :last_push_notification, :utc_datetime

    timestamps()
  end

  @permitted_fields ~w(alert_id user_id send_after message header phone_number email status last_push_notification)a
  @required_fields ~w(alert_id user_id message)a

  @doc """
  Changeset for persisting a sent Notification
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:status, [:sent, :failed])
    |> validate_email_or_phone
    |> foreign_key_constraint(:user_id)
  end

  defp validate_email_or_phone(changeset) do
    case {get_field(changeset, :email), get_field(changeset, :phone_number)} do
      {nil, nil} -> add_error(changeset, :dispatch, "Must have email OR phone number")
      _ -> changeset
    end
  end
end
