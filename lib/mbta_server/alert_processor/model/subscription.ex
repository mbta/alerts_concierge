defmodule MbtaServer.AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """

  alias MbtaServer.{AlertProcessor, Repo, User}
  alias AlertProcessor.{Helpers.DateTimeHelper, Model.InformedEntity}
  import Ecto.Query

  @type t :: %__MODULE__{
    alert_priority_type: atom,
    user_id: String.t,
    relevant_days: [:weekday | :saturday | :sunday],
    start_time: Time.t,
    end_time: Time.t
  }

  @type id :: String.t

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
    field :alert_priority_type, MbtaServer.AlertProcessor.AtomType
    field :relevant_days, MbtaServer.AlertProcessor.AtomArrayType
    field :start_time, :time, null: false
    field :end_time, :time, null: false

    timestamps()
  end

  @permitted_fields ~w(alert_priority_type user_id relevant_days start_time end_time)a
  @required_fields ~w(alert_priority_type user_id start_time end_time)a

  @doc """
  Changeset for persisting a Subscription
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:alert_priority_type, [:low, :medium, :high])
    |> validate_relevant_days
  end

  defp validate_relevant_days(changeset) do
    relevant_days = get_field(changeset, :relevant_days)
    if MapSet.subset?(MapSet.new(relevant_days), MapSet.new([{:array, :weekday}, {:array, :sunday}, {:array, :saturday}])) do
      changeset
    else
      add_error(changeset, :dispatch, "invalid relevant day type")
    end
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
  @spec timeframe_map(__MODULE__.t) :: %{optional(:sunday) => %{start: integer, end: integer},
                                         optional(:saturday) => %{start: integer, end: integer},
                                         optional(:weekday) => %{start: integer, end: integer}}
  def timeframe_map(subscription) do
    start_time_erl = Time.to_erl(subscription.start_time)
    end_time_erl = Time.to_erl(subscription.end_time)

    Map.new(subscription.relevant_days, fn(relevant_day) ->
      {relevant_day, %{start: DateTimeHelper.seconds_of_day(start_time_erl), end: DateTimeHelper.seconds_of_day(end_time_erl)}}
    end)
  end
end
