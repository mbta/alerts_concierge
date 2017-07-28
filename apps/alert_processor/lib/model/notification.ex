defmodule AlertProcessor.Model.Notification do
  @moduledoc """
  An individual message generated from an alert
  """

  alias AlertProcessor.Model.{Alert, User}

  @type t :: %__MODULE__{
    alert_id: String.t,
    user: User.t,
    send_after: DateTime.t,
    service_effect: String.t,
    description: String.t | nil,
    header: String.t,
    phone_number: String.t | nil,
    email: String.t,
    status: atom,
    last_push_notification: DateTime.t,
    alert: Alert.t
 }

  use Ecto.Schema
  import Ecto.Changeset
  alias AlertProcessor.{Model.User, Repo}

  @spec save(__MODULE__.t, atom) :: {:ok, __MODULE__.t} | {:error, Ecto.Changeset.t}
  def save(notification, status) do
    Repo.insert(__MODULE__.create_changeset(%{notification | status: status}))
  end

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "notifications" do
    belongs_to :user, User, type: :binary_id

    field :alert_id, :string
    field :send_after, :utc_datetime
    field :service_effect, :string
    field :description, :string
    field :header, :string
    field :phone_number, :string
    field :email, :string
    field :status, AlertProcessor.AtomType
    field :last_push_notification, :utc_datetime
    field :alert, :string, virtual: true

    timestamps()
  end

  @permitted_fields ~w(alert_id user_id send_after description service_effect header phone_number email status last_push_notification)a
  @required_fields ~w(alert_id user_id header service_effect)a

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
