defmodule AlertProcessor.Model.Trip do
  @moduledoc """
  A user's trip represents their commute. It contains a set of subscriptions
  and some other metadata, like whether it's a round trip or not.
  """

  alias AlertProcessor.Model.{Notification, User}
  alias AlertProcessor.Repo

  @type relevant_day :: :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
  @type station_feature :: :accessibility | :parking | :bike_storage
  @type alert_priority_type :: :low | :high

  @type t :: %__MODULE__{
    user_id: String.t | nil,
    alert_priority_type: alert_priority_type | nil,
    relevant_days: [relevant_day] | nil,
    start_time: Time.t | nil,
    end_time: Time.t | nil,
    notification_time: Time.t | nil,
    station_features: [station_feature] | nil
  }

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "trips" do
    belongs_to :user, User, type: :binary_id
    has_many :subscriptions, Notification

    field :alert_priority_type, AlertProcessor.AtomType, null: false
    field :relevant_days, {:array, AlertProcessor.AtomType}, null: false
    field :start_time, :time, null: false
    field :end_time, :time, null: false
    field :notification_time, :time, null: false
    field :station_features, {:array, AlertProcessor.AtomType}, null: false

    timestamps()
  end

  @required_fields ~w(user_id alert_priority_type relevant_days start_time end_time
    notification_time station_features)a
  @valid_relevant_days ~w(monday tuesday wednesday thursday friday saturday sunday)a
  @valid_station_features ~w(accessibility parking bike_storage)a
  @valid_alert_priority_types ~w(low high)a

  @doc """
  Changeset for creating a trip
  """
  @spec create_changeset(__MODULE__.t, map) :: Ecto.Changeset.t
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_subset(:relevant_days, @valid_relevant_days)
    |> validate_length(:relevant_days, min: 1)
    |> validate_subset(:station_features, @valid_station_features)
    |> validate_inclusion(:alert_priority_type, @valid_alert_priority_types)
  end

  def get_trips_by_user(user_id), do: Repo.all(from t in __MODULE__, where: t.user_id == ^user_id)
end