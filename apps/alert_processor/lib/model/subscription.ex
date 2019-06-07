defmodule AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """

  alias AlertProcessor.{Repo, TimeFrameComparison}

  alias AlertProcessor.Model.{
    Alert,
    InformedEntity,
    NotificationSubscription,
    Subscription,
    Trip,
    TripInfo,
    User
  }

  alias AlertProcessor.Helpers.DateTimeHelper
  alias AlertProcessor.ServiceInfoCache
  import Ecto.Query

  @type id :: String.t()
  @type subscription_type ::
          :bus | :subway | :commuter_rail | :ferry | :accessibility | :parking | :bike_storage
  @type subscription_info :: {__MODULE__.t(), [InformedEntity.t()]}
  @type relevant_day ::
          :weekday | :saturday | :sunday | :monday | :tuesday | :wednesday | :thursday | :friday
  @type direction :: 0 | 1
  @type facility_type ::
          :bike_storage
          | :electric_car_chargers
          | :elevator
          | :escalator
          | :parking_area
          | :pick_drop
          | :portable_boarding_lift
          | :tty_phone
          | :elevated_subplatform
  @type t :: %__MODULE__{
          user_id: String.t() | nil,
          trip_id: String.t() | nil,
          relevant_days: [relevant_day] | nil,
          start_time: Time.t() | nil,
          end_time: Time.t() | nil,
          travel_start_time: Time.t() | nil,
          travel_end_time: Time.t() | nil,
          origin: String.t() | nil,
          destination: String.t() | nil,
          type: subscription_type | nil,
          route: String.t() | nil,
          direction_id: direction | nil,
          origin_lat: float | nil,
          origin_long: float | nil,
          destination_lat: float | nil,
          destination_long: float | nil,
          rank: integer | nil,
          return_trip: boolean | nil,
          facility_types: [facility_type] | [],
          paused: boolean | nil,
          parent_id: String.t() | nil,
          child_subscriptions: [t()] | nil,
          admin?: boolean
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
    belongs_to(:user, User, type: :binary_id)
    belongs_to(:trip, Trip, type: :binary_id)
    has_many(:informed_entities, InformedEntity)
    has_many(:notification_subscriptions, NotificationSubscription)
    has_many(:notifications, through: [:notification_subscriptions, :notification])
    field(:relevant_days, {:array, AlertProcessor.AtomType})
    field(:start_time, :time, null: false)
    field(:end_time, :time, null: false)
    field(:travel_start_time, :time)
    field(:travel_end_time, :time)
    field(:origin, :string)
    field(:destination, :string)
    field(:type, AlertProcessor.AtomType)
    field(:route, :string)
    field(:route_type, :integer)
    field(:direction_id, :integer)
    field(:origin_lat, :float)
    field(:origin_long, :float)
    field(:destination_lat, :float)
    field(:destination_long, :float)
    field(:rank, :integer)
    field(:return_trip, :boolean)
    field(:facility_types, {:array, AlertProcessor.AtomType})
    field(:notification_type_to_send, AlertProcessor.AtomType, virtual: true)
    field(:paused, :boolean)
    field(:parent_id, :binary_id)
    field(:child_subscriptions, {:array, Subscription}, virtual: true, default: [])
    field(:admin?, :boolean)

    timestamps()
  end

  @permitted_fields ~w(user_id trip_id relevant_days start_time
    end_time travel_start_time travel_end_time type rank route return_trip route_type paused)a
  @required_fields ~w(user_id start_time end_time)a
  @update_permitted_fields ~w(relevant_days start_time end_time travel_start_time travel_end_time paused)a
  @valid_days ~w(weekday monday tuesday wednesday thursday friday saturday sunday)a

  @doc """
  Changeset for persisting a Subscription
  """
  @spec create_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
    |> validate_subset(:relevant_days, @valid_days)
    |> validate_length(:relevant_days, min: 1)
  end

  @doc """
  Changeset for updating a Subscription
  """
  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @update_permitted_fields)
    |> validate_subset(:relevant_days, @valid_days)
    |> validate_length(:relevant_days, min: 1)
  end

  def update_subscription(struct, params, originator) do
    struct
    |> update_changeset(params)
    |> PaperTrail.update(originator: User.wrap_id(originator), meta: %{owner: struct.user_id})
    |> normalize_papertrail_result()
  end

  @doc """
  Syncs a subscription's attributes per a given trip.
  """
  @spec sync_with_trip(__MODULE__.t(), Trip.t()) ::
          {:ok, Subscription.t()} :: {:error, Ecto.Changeset.t()}
  def sync_with_trip(%Subscription{} = subscription, %Trip{} = trip) do
    Subscription.SyncWithTrip.perform(subscription, trip)
  end

  def delete_subscription(struct, originator) do
    struct
    |> PaperTrail.delete(originator: User.wrap_id(originator), meta: %{owner: struct.user_id})
    |> normalize_papertrail_result()
  end

  def set_versioned_subscription(multi) do
    result =
      Repo.transaction(fn ->
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

    sub_version_changeset =
      Ecto.Changeset.cast(
        sub_version,
        %{meta: Map.merge(sub_version.meta, %{informed_entity_version_ids: ie_version_ids})},
        [:meta]
      )

    Repo.update(sub_version_changeset)
  end

  defp get_sub_version(data) do
    data
    |> Enum.filter(fn {name, _} ->
      :subscription == elem(name, 0)
    end)
    |> Enum.map(fn {name, %{version: sub_version}} ->
      case name do
        {:subscription, sub_index} ->
          {sub_index, sub_version}

        _ ->
          sub_version
      end
    end)
  end

  defp get_ie_version_ids(data, nil) do
    data
    |> Enum.filter(fn {name, _data} ->
      :new_informed_entity == elem(name, 0)
    end)
    |> Enum.map(fn {_name, %{version: %{id: id}}} ->
      id
    end)
  end

  defp get_ie_version_ids(data, sub_index) do
    data
    |> Enum.filter(fn {name, _data} ->
      :new_informed_entity == elem(name, 0) && sub_index == elem(name, 1)
    end)
    |> Enum.map(fn {_name, %{version: %{id: id}}} ->
      id
    end)
  end

  @doc """
  Fetches subscriptions with users eager loaded for a list of ids
  """
  @spec fetch_with_user([__MODULE__.id()]) :: [__MODULE__.t()]
  def fetch_with_user(subscription_ids) do
    query = from(s in __MODULE__, where: s.id in ^subscription_ids)

    query
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def for_user(user) do
    query =
      from(
        s in __MODULE__,
        where: s.user_id == ^user.id,
        preload: [:informed_entities]
      )

    Repo.all(query)
  end

  @doc """
  Fetches a subscription based on subscription and user ids. optionally preloads
  the informed entities.
  """
  def one_for_user!(subscription_id, user_id, preload_entities \\ false)

  def one_for_user!(subscription_id, user_id, false) do
    Repo.one!(from(s in __MODULE__, where: s.id == ^subscription_id and s.user_id == ^user_id))
  end

  def one_for_user!(subscription_id, user_id, true) do
    Repo.one!(
      from(
        s in __MODULE__,
        where: s.id == ^subscription_id and s.user_id == ^user_id,
        preload: [:informed_entities]
      )
    )
  end

  @doc """
  return relevant day of week subscription atom value based on day of week number
  """
  @spec relevant_day_of_week_type(integer) ::
          :sunday | :monday | :tuesday | :wednesday | :thursday | :friday | :saturday
  def relevant_day_of_week_type(day_of_week) do
    @relevant_day_of_week_types[day_of_week]
  end

  @doc """
  return relevant days pluralized and joined with comma.
  """
  @spec relevant_days_string(__MODULE__.t()) :: iodata
  def relevant_days_string(subscription) do
    capitalized_days =
      Enum.map(subscription.relevant_days, &String.capitalize(Atom.to_string(&1)))

    [Enum.intersperse(capitalized_days, "s, "), "s"]
  end

  @doc """
  converts a subscription struct into a map containing the relevant subscription day
  types which contain a start and end integer which represent the second of the day for
  the timestamp. This allows for comparing ranges of seconds for overlap.
  """
  @spec timeframe_map(__MODULE__.t()) :: TimeFrameComparison.timeframe_map()
  def timeframe_map(subscription) do
    relevant_days = weekday_to_days(subscription.relevant_days)

    Enum.reduce(relevant_days, %{}, fn relevant_day, acc ->
      overnight_timeframe = Time.compare(subscription.start_time, subscription.end_time) != :lt

      map_timeframe(
        relevant_day,
        overnight_timeframe,
        subscription.start_time,
        subscription.end_time,
        acc
      )
    end)
  end

  defp map_timeframe(day, true, start_time, end_time, acc) do
    acc
    |> Map.update(day, map_timeframe_range(start_time, ~T[23:59:59]), fn _ ->
      map_timeframe_range(start_time, end_time)
    end)
    |> Map.update(next_timeframe(day), map_timeframe_range(~T[00:00:00], end_time), fn _ ->
      map_timeframe_range(start_time, end_time)
    end)
  end

  defp map_timeframe(relevant_day, false, start_time, end_time, acc) do
    Map.put(acc, relevant_day, map_timeframe_range(start_time, end_time))
  end

  defp map_timeframe_range(start_time, end_time) do
    %{
      start: DateTimeHelper.seconds_of_day(start_time),
      end: DateTimeHelper.seconds_of_day(end_time)
    }
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
    [
      :bus,
      :subway,
      :commuter_rail,
      :ferry,
      :accessibility,
      :parking,
      :parking_area,
      :bike_storage,
      :elevated_subplatform,
      :portable_boarding_lift
    ]
  end

  @spec subscription_trip_ids(__MODULE__.t()) :: [TripInfo.id()]
  def subscription_trip_ids(subscription) do
    subscription.informed_entities
    |> Enum.filter(fn informed_entity ->
      InformedEntity.entity_type(informed_entity) == :trip
    end)
    |> Enum.map(& &1.trip)
  end

  defp normalize_papertrail_result({:ok, %{model: subscription}}), do: {:ok, subscription}
  defp normalize_papertrail_result(result), do: result

  @spec route_count(__MODULE__.t()) :: integer
  def route_count(subscription) do
    Enum.count(
      subscription.informed_entities,
      &(InformedEntity.entity_type(&1) == :route && &1.direction_id != nil)
    )
  end

  def get_last_inserted_timestamp() do
    Repo.one(
      from(s in __MODULE__, order_by: [desc: s.updated_at], select: s.updated_at, limit: 1)
    )
  end

  def add_latlong_to_subscription(subscription, origin, destination) do
    case {get_latlong_from_stop(origin), get_latlong_from_stop(destination)} do
      {nil, nil} ->
        subscription

      {{origin_lat, origin_long}, {destination_lat, destination_long}} ->
        %{
          subscription
          | origin_lat: origin_lat,
            origin_long: origin_long,
            destination_lat: destination_lat,
            destination_long: destination_long
        }
    end
  end

  defp get_latlong_from_stop(""), do: nil

  defp get_latlong_from_stop(stop_id) do
    case ServiceInfoCache.get_stop(stop_id) do
      {:ok, {_, _, latlong, _}} -> latlong
      _ -> nil
    end
  end

  @spec all_active_for_alert(Alert.t()) :: [__MODULE__.t()]
  def all_active_for_alert(alert) do
    alert
    |> get_alert_entity_lists()
    |> subscribers_match_query()
    |> where_subscription_not_paused()
    |> where_not_yet_notified(alert)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @spec paused_count() :: number
  def paused_count do
    Repo.one(
      from(
        s in __MODULE__,
        where: s.paused == true,
        select: count(s.id)
      )
    )
  end

  defp subscribers_match_query(
         route_ids: _,
         routes: _,
         stops: _,
         wildcard: true
       ),
       do: from(s in __MODULE__)

  defp subscribers_match_query(
         route_ids: route_ids,
         routes: routes,
         stops: stops,
         wildcard: false
       ) do
    # group (route_type ANY(..) OR route ANY(..) OR origin ANY(..) OR destination ANY (...)) together
    from(
      s in __MODULE__,
      where:
        s.admin? == true or s.route_type in ^route_ids or s.route in ^routes or s.origin in ^stops or
          s.destination in ^stops
    )
  end

  defp where_subscription_not_paused(query), do: from(s in query, where: s.paused == false)

  defp where_not_yet_notified(query, %Alert{id: alert_id}),
    do:
      from(
        s in query,
        where:
          not (s.user_id in fragment(
                 "select distinct on (n.user_id) n.user_id from notifications as n where n.alert_id = ? and n.status = 'sent'",
                 ^alert_id
               ))
      )

  @spec get_alert_entity_lists(Alert.t()) :: Keyword.t()
  defp get_alert_entity_lists(alert) do
    alert.informed_entities
    |> Enum.reduce(
      [route_ids: MapSet.new(), routes: MapSet.new(), stops: MapSet.new(), wildcard: false],
      fn entity, accumulator ->
        [
          route_ids: get_entity_value(accumulator[:route_ids], entity.route_type),
          routes: get_entity_value(accumulator[:routes], entity.route),
          stops: get_entity_value(accumulator[:stops], entity.stop),
          wildcard: handle_wildcard_entity(accumulator[:wildcard], entity)
        ]
      end
    )
    |> entity_sets_to_lists(Alert.mode_alert?(alert))
  end

  @spec entity_sets_to_lists(Keyword.t(), boolean) :: Keyword.t()
  defp entity_sets_to_lists(
         [route_ids: route_ids, routes: routes, stops: stops, wildcard: wildcard],
         include_route_ids?
       ) do
    route_ids = if include_route_ids?, do: MapSet.to_list(route_ids), else: []

    [
      route_ids: route_ids,
      routes: MapSet.to_list(routes),
      stops: MapSet.to_list(stops),
      wildcard: wildcard
    ]
  end

  @spec get_entity_value(MapSet.t(), any) :: MapSet.t()
  defp get_entity_value(entity_set, nil), do: entity_set
  defp get_entity_value(entity_set, value), do: MapSet.put(entity_set, value)

  @spec handle_wildcard_entity(boolean, InformedEntity.t()) :: boolean
  defp handle_wildcard_entity(true, _), do: true

  defp handle_wildcard_entity(_, entity) do
    if entity.route_type == nil && entity.route == nil && entity.stop == nil do
      true
    else
      false
    end
  end
end
