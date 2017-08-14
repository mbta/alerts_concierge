defmodule AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """

  alias AlertProcessor.{Helpers.DateTimeHelper, Model.InformedEntity, Model.Trip, Model.User, Repo, TimeFrameComparison}
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
    1 => :monday,
    2 => :tuesday,
    3 => :wednesday,
    4 => :thursday,
    5 => :friday,
    6 => :saturday,
    7 => :sunday
  }

  @subscription_type_values %{
    0 => "subway",
    1 => "subway",
    2 => "commuter_rail",
    3 => "bus",
    4 => "ferry"
  }

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "subscriptions" do
    belongs_to :user, User, type: :binary_id
    has_many :informed_entities, InformedEntity
    field :alert_priority_type, AlertProcessor.AtomType
    field :relevant_days, {:array, AlertProcessor.AtomType}
    field :start_time, :time, null: false
    field :end_time, :time, null: false
    field :origin, :string
    field :destination, :string
    field :type, AlertProcessor.AtomType

    timestamps()
  end

  @permitted_fields ~w(alert_priority_type user_id relevant_days start_time end_time type)a
  @required_fields ~w(alert_priority_type user_id start_time end_time)a
  @update_permitted_fields ~w(alert_priority_type relevant_days start_time end_time)a
  @valid_days ~w(weekday saturday sunday)a

  @doc """
  Changeset for persisting a Subscription
  """
  @spec create_changeset(__MODULE__.t, map) :: Ecto.Changeset.t
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:alert_priority_type, [:low, :medium, :high])
    |> validate_subset(:relevant_days, @valid_days)
    |> validate_length(:relevant_days, min: 1)
    |> validate_only_one_amenity
  end

  @doc """
  Changeset for updating a Subscription
  """
  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @update_permitted_fields)
    |> validate_inclusion(:alert_priority_type, [:low, :medium, :high])
    |> validate_subset(:relevant_days, @valid_days)
    |> validate_length(:relevant_days, min: 1)
  end

  def update_subscription(struct, params) do
    struct
    |> update_changeset(params)
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  def delete_subscription(struct) do
    struct
    |> PaperTrail.delete()
    |> normalize_papertrail_result()
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

  defp validate_only_one_amenity(changeset) do
    type = get_field(changeset, :type)
    user_id = get_field(changeset, :user_id)
    if type == :amenity and AlertProcessor.Model.Subscription.amenity_exists(user_id) do
      add_error(changeset, :type, "User can only have one amenity")
    else
      changeset
    end
  end

  def amenity_query(user_id) do
    from s in __MODULE__,
      where: s.user_id == ^user_id and s.type == "amenity"
  end

  def amenity_exists(user_id) do
    query = amenity_query(user_id)

    case Repo.all(query) do
      [_] -> true
      [] -> false
    end
  end

  def user_amenity(user) do
    amenity_query(user.id)
    |> Repo.one
  end

  @doc """
  Fetches a subscription based on subscription and user ids. optionally preloads
  the informed entities.
  """
  def one_for_user!(subscription_id, user_id, preload_entities \\ false)
  def one_for_user!(subscription_id, user_id, false) do
    Repo.one!(from s in __MODULE__,
      where: s.id == ^subscription_id and s.user_id == ^user_id)
  end
  def one_for_user!(subscription_id, user_id, true) do
    Repo.one!(from s in __MODULE__,
      where: s.id == ^subscription_id and s.user_id == ^user_id,
      preload: [:informed_entities])
  end

  @doc """
  return relevant day of week subscription atom value based on day of week number
  """
  @spec relevant_day_of_week_type(integer) :: :sunday | :monday | :tuesday | :wednesday | :thursday | :friday | :saturday
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
    Enum.reduce(subscription.relevant_days, %{}, fn(relevant_day, acc) ->
      overnight_timeframe = Time.compare(subscription.start_time, subscription.end_time) != :lt
      map_timeframe(relevant_day, overnight_timeframe, subscription.start_time, subscription.end_time, acc)
    end)
  end

  defp map_timeframe(:weekday, true, start_time, end_time, acc) do
    acc
    |> Map.update(:monday, map_timeframe_range(start_time, ~T[23:59:59]), fn(_) ->
         map_timeframe_range(start_time, end_time)
       end)
    |> Map.put(:tuesday, map_timeframe_range(start_time, end_time))
    |> Map.put(:wednesday, map_timeframe_range(start_time, end_time))
    |> Map.put(:thursday, map_timeframe_range(start_time, end_time))
    |> Map.put(:friday, map_timeframe_range(start_time, end_time))
    |> Map.update(:saturday, map_timeframe_range(~T[00:00:00], end_time), fn(_) ->
         map_timeframe_range(start_time, end_time)
       end)
  end
  defp map_timeframe(:saturday, true, start_time, end_time, acc) do
    acc
    |> Map.update(:saturday, map_timeframe_range(start_time, ~T[23:59:59]), fn(_) ->
         map_timeframe_range(start_time, end_time)
       end)
    |> Map.update(:sunday, map_timeframe_range(~T[00:00:00], end_time), fn(_) ->
         map_timeframe_range(start_time, end_time)
       end)
  end
  defp map_timeframe(:sunday, true, start_time, end_time, acc) do
    acc
    |> Map.update(:sunday, map_timeframe_range(start_time, ~T[23:59:59]), fn(_) ->
         map_timeframe_range(start_time, end_time)
       end)
    |> Map.update(:monday, map_timeframe_range(~T[00:00:00], end_time), fn(_) ->
         map_timeframe_range(start_time, end_time)
       end)
  end
  defp map_timeframe(:weekday, false, start_time, end_time, acc) do
    if after_midnight?(start_time) do
      acc
      |> Map.put(:tuesday, map_timeframe_range(start_time, end_time))
      |> Map.put(:wednesday, map_timeframe_range(start_time, end_time))
      |> Map.put(:thursday, map_timeframe_range(start_time, end_time))
      |> Map.put(:friday, map_timeframe_range(start_time, end_time))
      |> Map.put(:saturday, map_timeframe_range(start_time, end_time))
    else
      acc
      |> Map.put(:monday, map_timeframe_range(start_time, end_time))
      |> Map.put(:tuesday, map_timeframe_range(start_time, end_time))
      |> Map.put(:wednesday, map_timeframe_range(start_time, end_time))
      |> Map.put(:thursday, map_timeframe_range(start_time, end_time))
      |> Map.put(:friday, map_timeframe_range(start_time, end_time))
    end
  end
  defp map_timeframe(relevant_day, false, start_time, end_time, acc) do
    if after_midnight?(start_time) do
      Map.put(acc, next_timeframe(relevant_day), map_timeframe_range(start_time, end_time))
    else
      Map.put(acc, relevant_day, map_timeframe_range(start_time, end_time))
    end
  end

  defp map_timeframe_range(start_time, end_time) do
    %{start: DateTimeHelper.seconds_of_day(start_time), end: DateTimeHelper.seconds_of_day(end_time)}
  end

  defp after_midnight?(timestamp) do
    local_timestamp = Time.compare(timestamp, ~T[04:00:00])
    local_timestamp != :gt
  end

  defp next_timeframe(:weekday), do: :saturday
  defp next_timeframe(:saturday), do: :sunday
  defp next_timeframe(:sunday), do: :monday

  @doc """
  function used to make sure subscription type atoms are available in runtime
  for String.to_existing_atom calls.
  """
  def subscription_types do
    [:bus, :subway, :commuter_rail, :boat, :amenity]
  end

  def subscription_type_from_route_type(route_type) do
    @subscription_type_values[route_type]
  end

  @spec subscription_trip_ids(__MODULE__.t) :: [Trip.id]
  def subscription_trip_ids(subscription) do
    subscription.informed_entities
    |> Enum.filter(fn(informed_entity) ->
         InformedEntity.entity_type(informed_entity) == :trip
       end)
    |> Enum.map(& &1.trip)
  end

  def full_mode_subscription_types_for_user(user) do
    Repo.all(from s in __MODULE__,
      where: s.user_id == ^user.id,
      where: fragment("? not in (select ie.subscription_id from informed_entities ie)", s.id),
      order_by: s.type,
      distinct: true,
      select: s.type)
  end

  defp normalize_papertrail_result({:ok, %{model: subscription}}), do: {:ok, subscription}
  defp normalize_papertrail_result(result), do: result
end
