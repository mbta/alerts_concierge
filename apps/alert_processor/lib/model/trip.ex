defmodule AlertProcessor.Model.Trip do
  @moduledoc """
  A user's trip represents their commute. It contains a set of subscriptions
  and some other metadata, like whether it's a round trip or not.
  """

  alias AlertProcessor.Model.{Trip, Subscription, User}
  alias AlertProcessor.Repo

  @type relevant_day ::
          :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
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
  @type alert_priority_type :: :low | :high
  @type trip_type :: :commute | :accessibility

  @type t :: %__MODULE__{
          user_id: String.t() | nil,
          alert_priority_type: alert_priority_type | nil,
          relevant_days: [relevant_day] | nil,
          start_time: Time.t() | nil,
          end_time: Time.t() | nil,
          return_start_time: Time.t() | nil,
          return_end_time: Time.t() | nil,
          facility_types: [facility_type] | [],
          roundtrip: boolean,
          trip_type: trip_type
        }

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "trips" do
    belongs_to(:user, User, type: :binary_id)
    has_many(:subscriptions, Subscription, on_delete: :delete_all)

    field(:alert_priority_type, AlertProcessor.AtomType, null: false)
    field(:relevant_days, {:array, AlertProcessor.AtomType}, null: false)
    field(:start_time, :time, null: false)
    field(:end_time, :time, null: false)
    field(:return_start_time, :time, null: true)
    field(:return_end_time, :time, null: true)
    field(:facility_types, {:array, AlertProcessor.AtomType}, null: false)
    field(:roundtrip, :boolean, null: false)
    field(:trip_type, AlertProcessor.AtomType, null: false, default: :commute)

    timestamps()
  end

  @permitted_fields ~w(user_id alert_priority_type relevant_days start_time end_time
    facility_types roundtrip return_start_time return_end_time)a
  @required_fields ~w(user_id alert_priority_type relevant_days start_time end_time
    facility_types roundtrip)a
  @valid_relevant_days ~w(monday tuesday wednesday thursday friday saturday sunday)a
  @valid_facility_types ~w(bike_storage electric_car_chargers elevator escalator parking_area pick_drop portable_boarding_lift tty_phone elevated_subplatform)a
  @valid_alert_priority_types ~w(low high)a
  @update_permitted_fields ~w(
    relevant_days
    start_time
    end_time
    return_start_time
    return_end_time
    facility_types
  )a

  @doc """
  Changeset for creating a trip
  """
  @spec create_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
    |> validate_subset(:relevant_days, @valid_relevant_days)
    |> validate_length(:relevant_days, min: 1)
    |> validate_subset(:facility_types, @valid_facility_types)
    |> validate_inclusion(:alert_priority_type, @valid_alert_priority_types)
  end

  @doc """
  Changeset for updating a trip.

  Only allowed to update the following:
  * relevant_days
  * start_time
  * end_time
  * return_start_time
  * return_end_time

  """
  @spec update_changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @update_permitted_fields)
    |> validate_subset(:relevant_days, @valid_relevant_days)
    |> validate_length(:relevant_days, min: 1)
  end

  @doc """
  Updates a trip and it's associated subscriptions.

  ## Examples

      iex> update(trip, %{field: new_value})
      {:ok, %Trip{}}

      iex> update(trip, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update(__MODULE__.t(), map) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def update(%__MODULE__{} = trip, params) do
    update_result =
      trip
      |> update_changeset(params)
      |> Repo.update()

    sync_subscriptions(update_result)
    update_result
  end

  def get_trips_by_user(user_id) do
    subscriptions_query = from(s in Subscription, where: s.return_trip == false, order_by: s.rank)

    Repo.all(
      from(
        t in __MODULE__,
        where: t.user_id == ^user_id,
        preload: [subscriptions: ^subscriptions_query]
      )
    )
  end

  @doc """
  Deletes a trip and associated subscriptions.

  ## Examples

      iex> delete(trip)
      {:ok, %Trip{}}

      iex> delete(trip)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete(Trip.t()) :: {:ok, Trip.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Trip{} = trip) do
    Repo.delete(trip)
  end

  @doc """
  Returns trip for the given trip id. Preloads associates subscriptions.

  Return nil if no result was found. Raises if more than one entry.

  ## Examples

      iex> find_by_id(id)
      %Trip{...}

      iex> find_by_id(non_existent_id)
      nil

  """
  @spec find_by_id(String.t()) :: Trip.t() | nil | no_return
  def find_by_id(id) do
    query =
      from(
        t in __MODULE__,
        left_join: s in assoc(t, :subscriptions),
        where: t.id == ^id,
        preload: [subscriptions: s]
      )

    Repo.one(query)
  end

  defp sync_subscriptions({:error, _}), do: :ignore

  defp sync_subscriptions({:ok, %Trip{} = trip}) do
    trip = Repo.preload(trip, :subscriptions)

    for subscription <- trip.subscriptions do
      Subscription.sync_with_trip(subscription, trip)
    end
  end
end
