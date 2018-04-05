defmodule ConciergeSite.V2.AccessibilityTripController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.{Trip, Subscription, User}
  alias Ecto.Multi
  import Ecto.Changeset

  def new(conn, _params, _user, _claims) do
    render conn, "new.html", changeset: make_changeset()
  end

  def create(conn, %{"trip" => trip}, user, {:ok, claims}) do
    trip
    |> make_changeset()
    |> validate_input()
    |> save_trip(conn, user, claims)
  end

  defp save_trip(%{valid?: false} = changeset, conn, _user, _claims) do
    conn
    |> put_flash(:error, "Please correct the error and re-submit.")
    |> render("new.html", %{changeset: changeset})
  end

  defp save_trip(changeset, conn, user, claims) do
    trip = make_trip(changeset, user)
    subscriptions = make_stop_subscriptions(changeset, trip) ++ make_route_subscriptions(changeset, trip)

    multi = build_trip_transaction(trip, subscriptions, user, Map.get(claims, "imp", user.id))
    case Subscription.set_versioned_subscription(multi) do
      :ok ->
        conn
        |> put_flash(:info, "Success! Accessibility trip created.")
        |> redirect(to: v2_trip_path(conn, :index))
      :error ->
        conn
        |> put_flash(:error, "There was an error creating your trip. Please try again.")
        |> render("new.html")
    end
  end

  defp build_trip_transaction(trip, subscriptions, user, originator) do
    origin = if user.id != User.wrap_id(originator).id do "admin:create-subscription" end

    multi = Multi.run(Multi.new, {:trip, 0}, fn _ ->
      PaperTrail.insert(trip, originator: User.wrap_id(originator), meta: %{owner: user.id}, origin: origin)
    end)

    subscriptions
    |> Enum.with_index
    |> Enum.reduce(multi, fn({sub, index}, acc) ->
      sub_to_insert = sub
      |> Map.merge(%{id: Ecto.UUID.generate, rank: index})
      |> Subscription.create_changeset()

      acc
      |> Multi.run({:subscription, index}, fn _ ->
           PaperTrail.insert(sub_to_insert, originator: User.wrap_id(originator), meta: %{owner: user.id}, origin: origin)
         end)
    end)
  end

  defp make_changeset(params \\ %{}) do
    types = %{
      relevant_days: {:array, :string},
      stops: {:array, :string},
      routes: {:array, :string},
      elevator: :string,
      escalator: :string}

    {%{}, types}
    |> cast(params, Map.keys(types))
  end

  defp validate_input(changeset) do
    changeset
    |> validate_days()
    |> validate_features()
    |> validate_stops()
    |> validate_routes()
  end

  defp validate_days(%{changes: %{relevant_days: []}} = changeset) do
    add_error changeset, :relevant_days, "at least one day must be selected"
  end
  defp validate_days(changeset), do: changeset

  defp validate_features(%{changes: %{elevator: "false", escalator: "false"}} = changeset) do
    add_error changeset, :escalator, "at least one accessibility feature must be selected"
  end
  defp validate_features(changeset), do: changeset

  defp validate_stops(%{changes: %{stops: [], routes: []}} = changeset) do
    add_error changeset, :stops, "must choose at least one stop or line"
  end
  defp validate_stops(changeset), do: changeset

  defp validate_routes(%{changes: %{stops: [], routes: []}} = changeset) do
    add_error changeset, :stops, "must choose at least one stop or line"
  end
  defp validate_routes(changeset), do: changeset

  defp make_trip(%{changes: %{relevant_days: relevant_days, elevator: elevator, escalator: escalator}}, user) do
    %Trip{
      id: Ecto.UUID.generate,
      user_id: user.id,
      alert_priority_type: "low",
      relevant_days: Enum.map(relevant_days, &String.to_existing_atom/1),
      start_time: ~T[03:20:00],
      end_time: ~T[01:50:00],
      facility_types: input_to_facility_types(%{"elevator" => elevator, "escalator" => escalator}),
      roundtrip: false,
      trip_type: :accessibility
    }
  end

  defp input_to_facility_types(params) do
    ["elevator", "escalator"]
    |> Enum.reduce([], fn(type, acc) ->
      if params[type] == "true" do
        acc ++ [String.to_existing_atom(type)]
      else
        acc
      end
    end)
  end

  defp make_stop_subscriptions(%{changes: %{stops: stops}}, trip) do
    Enum.map(stops, fn(stop) ->
      trip
      |> make_subscription()
      |> Map.put(:origin, stop)
      |> Map.put(:destination, stop)
      |> Subscription.add_latlong_to_subscription(stop, stop)
    end)
  end

  defp make_route_subscriptions(%{changes: %{routes: routes}}, trip) do
    Enum.map(routes, fn(route) ->
      route_type = if route == "Green", do: 0, else: 1
      trip
      |> make_subscription()
      |> Map.put(:route, route)
      |> Map.put(:route_type, route_type)
    end)
  end

  defp make_subscription(trip) do
    %Subscription{
      alert_priority_type: "low",
      trip_id: trip.id,
      user_id: trip.user_id,
      relevant_days: trip.relevant_days,
      start_time: trip.start_time,
      end_time: trip.end_time,
      type: :accessibility,
      return_trip: false
    }
  end
end
