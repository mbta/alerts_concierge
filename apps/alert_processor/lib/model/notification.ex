defmodule AlertProcessor.Model.Notification do
  @moduledoc """
  An individual message generated from an alert
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{Alert, User}

  @type notification_type :: :initial | :update | :reminder | :all_clear

  @type t :: %__MODULE__{
          alert_id: String.t() | nil,
          user_id: String.t() | nil,
          send_after: DateTime.t() | nil,
          service_effect: String.t() | nil,
          description: String.t() | nil,
          url: String.t() | nil,
          header: String.t(),
          phone_number: String.t() | nil,
          email: String.t() | nil,
          status: atom,
          last_push_notification: DateTime.t() | nil,
          alert: Alert.t() | nil,
          closed_timestamp: DateTime.t() | nil,
          type: notification_type | nil,
          image_url: String.t() | nil,
          image_alternative_text: String.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "notifications" do
    belongs_to(:user, User, type: :binary_id)
    has_many(:notification_subscriptions, AlertProcessor.Model.NotificationSubscription)
    has_many(:subscriptions, through: [:notification_subscriptions, :subscription])

    field(:alert_id, :string)
    field(:send_after, :utc_datetime)
    field(:service_effect, :string)
    field(:description, :string)
    field(:url, :string)
    field(:header, :string)
    field(:phone_number, :string)
    field(:email, :string)
    field(:status, AlertProcessor.AtomType)
    field(:last_push_notification, :utc_datetime)
    field(:alert, :string, virtual: true)
    field(:closed_timestamp, :utc_datetime)
    field(:type, AlertProcessor.AtomType)
    field(:image_url, :string)
    field(:image_alternative_text, :string)

    timestamps(type: :utc_datetime)
  end

  @spec save(t(), atom) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def save(notification, status) do
    Repo.insert(
      %{notification | status: status, user_id: notification.user.id}
      |> create_changeset()
      |> cast_assoc(:notification_subscriptions)
    )
  end

  @permitted_fields ~w(alert_id user_id send_after description url service_effect
    header phone_number email status last_push_notification closed_timestamp)a
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

  def most_recent_for_alerts(alerts) do
    alert_ids = Enum.map(alerts, & &1.id)

    Repo.all(
      from(
        n in __MODULE__,
        where: n.alert_id in ^alert_ids,
        where: n.status == "sent",
        preload: [subscriptions: :user],
        distinct: [:alert_id, :user_id],
        order_by: [desc: n.inserted_at]
      )
    )
  end

  @spec most_recent_if_outdated_for_alert(AlertProcessor.Model.Alert.t()) :: any()
  def most_recent_if_outdated_for_alert(%Alert{
        id: id,
        last_push_notification: last_push_notification
      }) do
    most_recent_subquery =
      from(
        n in __MODULE__,
        where: n.alert_id == ^id,
        where: n.status == "sent",
        distinct: :user_id,
        order_by: [desc: n.last_push_notification]
      )

    Repo.all(
      from(
        n in subquery(most_recent_subquery),
        where: n.last_push_notification < ^last_push_notification,
        preload: [subscriptions: :user]
      )
    )
  end

  @spec image_alternative_text(t()) :: String.t()
  @spec image_alternative_text(t(), email? :: boolean()) :: String.t()
  def image_alternative_text(notification, email? \\ false)

  def image_alternative_text(%__MODULE__{image_alternative_text: nil} = notification, email?),
    do: image_alternative_text(%__MODULE__{notification | image_alternative_text: ""}, email?)

  def image_alternative_text(%__MODULE__{image_alternative_text: image_alternative_text}, true) do
    [image_alternative_text, "Link opens a full-size version of the image."]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
  end

  def image_alternative_text(%__MODULE__{image_alternative_text: image_alternative_text}, false),
    do: image_alternative_text
end
