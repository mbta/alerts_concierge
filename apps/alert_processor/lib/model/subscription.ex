defmodule AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """

  alias AlertProcessor.{Helpers.DateTimeHelper, Model.InformedEntity, Model.User, Repo, TimeFrameComparison}
  import Ecto.Query

  @type id :: String.t
  @type subscription_type :: :bus | :subway | :commuter_rail | :boat | :amenity
  @type subscription_info :: {__MODULE__.t, [InformedEntity.t]}
  @type relevant_day :: :weekday | :saturday | :sunday
  @type t :: %__MODULE__{
    alert_priority_type: atom,
    user_id: String.t,
    relevant_days: [relevant_day],
    start_time: Time.t,
    end_time: Time.t,
    origin: String.t,
    destination: String.t,
    type: subscription_type
  }

  @alert_priority_type_values %{
    low: 1,
    medium: 2,
    high: 3
  }

  @relevant_day_of_week_types %{
    1 => :weekday,
    2 => :weekday,
    3 => :weekday,
    4 => :weekday,
    5 => :weekday,
    6 => :saturday,
    7 => :sunday
  }

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "subscriptions" do
    belongs_to :user, User, type: :binary_id
    has_many :informed_entities, InformedEntity
    field :alert_priority_type, AlertProcessor.AtomType
    field :relevant_days, AlertProcessor.AtomArrayType
    field :start_time, :time, null: false
    field :end_time, :time, null: false
    field :origin, :string
    field :destination, :string
    field :type, AlertProcessor.AtomType

    timestamps()
  end

  @permitted_fields ~w(alert_priority_type user_id relevant_days start_time end_time)a
  @required_fields ~w(alert_priority_type user_id start_time end_time)a
  @valid_days [array: :weekday, array: :saturday, array: :sunday]

  @doc """
  Changeset for persisting a Subscription
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:alert_priority_type, [:low, :medium, :high])
    |> validate_subset(:relevant_days, @valid_days)
    |> validate_length(:relevant_days, min: 1)
  end

  @doc """
  return the numeric value for a subscription's alert priority type.
  the higher the number, the fewer amount of alerts should be received.
  """
  @spec severity_value(atom) :: integer
  def severity_value(alert_priority_type) do
    @alert_priority_type_values[alert_priority_type]
  end

  @doc """
  Fetches subscriptions with users eager loaded for a list of ids
  """
  @spec fetch_with_user([__MODULE__.id]) :: [__MODULE__.t]
  def fetch_with_user(subscription_ids) do
    query = from s in __MODULE__,
      where: s.id in ^subscription_ids

    query
    |> Repo.all
    |> Repo.preload(:user)
  end

  def for_user(user) do
    query = from s in __MODULE__,
      where: s.user_id == ^user.id,
      preload: [:informed_entities]

    Repo.all(query)
  end

  @doc """
  return relevant day of week subscription atom value based on day of week number
  """
  @spec relevant_day_of_week_type(integer) :: :saturday | :sunday | :weekday
  def relevant_day_of_week_type(day_of_week) do
    @relevant_day_of_week_types[day_of_week]
  end

  @doc """
  converts a subscription struct into a map containing the relevant subscription day
  types which contain a start and end integer which represent the second of the day for
  the timestamp. This allows for comparing ranges of seconds for overlap.
  """
  @spec timeframe_map(__MODULE__.t) :: TimeFrameComparison.timeframe_map
  def timeframe_map(subscription) do
    Map.new(subscription.relevant_days, fn(relevant_day) ->
      {relevant_day, %{start: DateTimeHelper.seconds_of_day(subscription.start_time), end: DateTimeHelper.seconds_of_day(subscription.end_time)}}
    end)
  end

  @doc """
  function used to make sure subscription type atoms are available in runtime
  for String.to_existing_atom calls.
  """
  def subscription_types do
    [:bus, :subway, :commuter_rail, :boat, :amenity]
  end
end
