defmodule AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """

  alias AlertProcessor.{Repo, TimeFrameComparison}
  alias AlertProcessor.Model.{InformedEntity, TripInfo, User, Trip, Subscription}
  alias AlertProcessor.Helpers.DateTimeHelper
  import Ecto.Query

  @type id :: String.t
  @type subscription_type :: :bus | :subway | :commuter_rail | :ferry | :accessibility | :parking | :bike_storage
  @type subscription_info :: {__MODULE__.t, [InformedEntity.t]}
  @type relevant_day :: :weekday | :saturday | :sunday | :monday | :tuesday | :wednesday | :thursday | :friday
  @type direction :: 0 | 1
  @type facility_type :: :bike_storage | :electric_car_chargers | :elevator | :escalator | :parking_area | :pick_drop | :portable_boarding_lift | :tty_phone | :elevated_subplatform
  @type t :: %__MODULE__{
    alert_priority_type: atom,
    user_id: String.t | nil,
    trip_id: String.t | nil,
    relevant_days: [relevant_day] | nil,
    start_time: Time.t | nil,
    end_time: Time.t | nil,
    origin: String.t | nil,
    destination: String.t | nil,
    type: subscription_type | nil,
    route: String.t | nil,
    direction_id: direction | nil,
    origin_lat: float | nil,
    origin_long: float | nil,
    destination_lat: float | nil,
    destination_long: float | nil,
    rank: integer | nil,
    return_trip: boolean | nil,
    facility_types: [facility_type] | []
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

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "subscriptions" do
    belongs_to :user, User, type: :binary_id
    belongs_to :trip, Trip, type: :binary_id
    has_many :informed_entities, InformedEntity
    field :alert_priority_type, AlertProcessor.AtomType
    field :relevant_days, {:array, AlertProcessor.AtomType}
    field :start_time, :time, null: false
    field :end_time, :time, null: false
    field :origin, :string
    field :destination, :string
    field :type, AlertProcessor.AtomType
    field :route, :string
    field :route_type, :integer
    field :direction_id, :integer
    field :origin_lat, :float
    field :origin_long, :float
    field :destination_lat, :float
    field :destination_long, :float
    field :rank, :integer
    field :return_trip, :boolean
    field :facility_types, {:array, AlertProcessor.AtomType}

    timestamps()
  end

  @permitted_fields ~w(alert_priority_type user_id trip_id relevant_days start_time
    end_time type rank route return_trip)a
  @required_fields ~w(alert_priority_type user_id start_time end_time)a
  @update_permitted_fields ~w(alert_priority_type relevant_days start_time end_time)a
  @valid_days ~w(weekday monday tuesday wednesday thursday friday saturday sunday)a

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

  def update_subscription(struct, params, originator) do
    origin =
      if struct.user_id != User.wrap_id(originator).id do
        "admin:update-subscription"
      end
    struct
    |> update_changeset(params)
    |> PaperTrail.update(originator: User.wrap_id(originator), meta: %{owner: struct.user_id}, origin: origin)
    |> normalize_papertrail_result()
  end

  @doc """
  Syncs a subscription's attributes per a given trip.
  """
  @spec sync_with_trip(__MODULE__.t, Trip.t) :: {:ok, Subscription.t} :: {:error, Ecto.Changeset.t}
  def sync_with_trip(%Subscription{} = subscription, %Trip{} = trip) do
    Subscription.SyncWithTrip.perform(subscription, trip)
  end

  def delete_subscription(struct, originator) do
    originator = User.wrap_id(originator)
    origin =
      if struct.user_id != originator.id do
        "admin:delete-subscription"
      end
    struct
    |> PaperTrail.delete(originator: originator, meta: %{owner: struct.user_id}, origin: origin)
    |> normalize_papertrail_result()
  end

  def set_versioned_subscription(multi) do
    result = Repo.transaction(fn ->
      with {:ok, result} <- Repo.transaction(multi),
        :ok <- associate_informed_entity_versions(result) do
          :ok
      else
        _ -> Repo.rollback(:undo_multi)
      end
    end)

    case result do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  defp associate_informed_entity_versions(result) do
    data = Map.to_list(result)
    sub_versions = get_sub_version(data)

    for sub_version <- sub_versions do
      do_associate_informed_entity_versions(data, sub_version)
    end
    :ok
  end

  defp do_associate_informed_entity_versions(data, {sub_index, sub_version}) do
    do_associate_informed_entity_versions(data, sub_version, sub_index)
  end
  defp do_associate_informed_entity_versions(data, sub_version, sub_index \\ nil) do
    ie_version_ids = get_ie_version_ids(data, sub_index)
    sub_version_changeset = Ecto.Changeset.cast(
      sub_version,
      %{meta: Map.merge(sub_version.meta, %{informed_entity_version_ids: ie_version_ids})},
      [:meta]
    )

    Repo.update(sub_version_changeset)
  end

  defp get_sub_version(data) do
    data
    |> Enum.filter(fn({name, _}) ->
      :subscription == elem(name, 0)
    end)
    |> Enum.map(fn({name, %{version: sub_version}}) ->
      case name do
        {:subscription, sub_index} ->
          {sub_index, sub_version}
          _ -> sub_version
      end
    end)
  end

  defp get_ie_version_ids(data, nil) do
    data
    |> Enum.filter(fn({name, _data}) ->
      :new_informed_entity == elem(name, 0)
    end)
    |> Enum.map(fn({_name, %{version: %{id: id}}}) ->
      id
    end)
  end
  defp get_ie_version_ids(data, sub_index) do
    data
    |> Enum.filter(fn({name, _data}) ->
      :new_informed_entity == elem(name, 0) && sub_index == elem(name, 1)
    end)
    |> Enum.map(fn({_name, %{version: %{id: id}}}) ->
      id
    end)
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
  return string representation of severities that match subscription.
  """
  @spec severity_string(__MODULE__.t) :: String.t
  def severity_string(%__MODULE__{alert_priority_type: :low}), do: "High-, medium-, and low-priority alerts"
  def severity_string(%__MODULE__{alert_priority_type: :medium}), do: "High- and medium-priority alerts"
  def severity_string(%__MODULE__{alert_priority_type: :high}), do: "High-priority alerts"

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
  return relevant days pluralized and joined with comma.
  """
  @spec relevant_days_string(__MODULE__.t) :: iodata
  def relevant_days_string(subscription) do
    capitalized_days = Enum.map(subscription.relevant_days, &String.capitalize(Atom.to_string(&1)))
    [Enum.intersperse(capitalized_days, "s, "), "s"]
  end

  @doc """
  converts a subscription struct into a map containing the relevant subscription day
  types which contain a start and end integer which represent the second of the day for
  the timestamp. This allows for comparing ranges of seconds for overlap.
  """
  @spec timeframe_map(__MODULE__.t) :: TimeFrameComparison.timeframe_map
  def timeframe_map(subscription) do
    relevant_days = weekday_to_days(subscription.relevant_days)
    Enum.reduce(relevant_days, %{}, fn(relevant_day, acc) ->
      overnight_timeframe = Time.compare(subscription.start_time, subscription.end_time) != :lt
      map_timeframe(relevant_day, overnight_timeframe, subscription.start_time, subscription.end_time, acc)
    end)
  end

  defp map_timeframe(day, true, start_time, end_time, acc) do
    acc
    |> Map.update(day, map_timeframe_range(start_time, ~T[23:59:59]), fn(_) ->
         map_timeframe_range(start_time, end_time)
       end)
    |> Map.update(next_timeframe(day), map_timeframe_range(~T[00:00:00], end_time), fn(_) ->
         map_timeframe_range(start_time, end_time)
       end)
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

  defp weekday_to_days(relevant_days) do
    Enum.flat_map(relevant_days, fn
      :weekday -> [:monday, :tuesday, :wednesday, :thursday, :friday]
      day -> [day]
    end)
  end

  defp next_timeframe(:monday), do: :tuesday
  defp next_timeframe(:tuesday), do: :wednesday
  defp next_timeframe(:wednesday), do: :thursday
  defp next_timeframe(:thursday), do: :friday
  defp next_timeframe(:friday), do: :saturday
  defp next_timeframe(:saturday), do: :sunday
  defp next_timeframe(:sunday), do: :monday

  @doc """
  function used to make sure subscription type atoms are available in runtime
  for String.to_existing_atom calls.
  """
  def subscription_types do
    [:bus, :subway, :commuter_rail, :ferry, :accessibility, :parking, :parking_area, :bike_storage, :elevated_subplatform, :portable_boarding_lift]
  end

  @spec subscription_trip_ids(__MODULE__.t) :: [TripInfo.id]
  def subscription_trip_ids(subscription) do
    subscription.informed_entities
    |> Enum.filter(fn(informed_entity) ->
         InformedEntity.entity_type(informed_entity) == :trip
       end)
    |> Enum.map(& &1.trip)
  end

  defp normalize_papertrail_result({:ok, %{model: subscription}}), do: {:ok, subscription}
  defp normalize_papertrail_result(result), do: result

  @spec route_count(__MODULE__.t) :: integer
  def route_count(subscription) do
    Enum.count(subscription.informed_entities, &InformedEntity.entity_type(&1) == :route && &1.direction_id != nil)
  end

  def get_last_inserted_timestamp() do
    Repo.one(from s in __MODULE__, order_by: [desc: s.updated_at], select: s.updated_at, limit: 1)
  end
end
