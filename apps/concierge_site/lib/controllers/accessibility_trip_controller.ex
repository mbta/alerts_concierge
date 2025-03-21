defmodule ConciergeSite.AccessibilityTripController do
  use ConciergeSite.Web, :controller

  import Ecto.Changeset
  import Phoenix.HTML.Link

  alias AlertProcessor.Authorizer.TripAuthorizer
  alias AlertProcessor.Model.{Trip, Subscription}
  alias ConciergeSite.ParamParsers.TripParams
  alias Ecto.Multi

  action_fallback(ConciergeSite.FallbackController)

  @valid_facility_types ~w(elevator escalator)

  def new(conn, _params) do
    render(conn, "new.html", changeset: make_changeset())
  end

  def create(%{assigns: %{current_user: user}} = conn, %{"trip" => trip}) do
    trip
    |> default_values()
    |> make_changeset()
    |> validate_input()
    |> save_trip(conn, user)
  end

  def edit(%{assigns: %{current_user: user}} = conn, %{"id" => id}) do
    with {:trip, %Trip{} = trip} <- {:trip, Trip.find_by_id(id)},
         {:ok, :authorized} <- TripAuthorizer.authorize(trip, user),
         {:changeset, changeset} <- {:changeset, Trip.update_changeset(trip)} do
      conn
      |> message_if_paused(trip)
      |> render("edit.html", trip: trip, changeset: changeset)
    else
      {:trip, nil} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :not_found}
    end
  end

  def update(%{assigns: %{current_user: user}} = conn, %{"id" => id, "trip" => trip_params}) do
    with {:trip, %Trip{} = trip} <- {:trip, Trip.find_by_id(id)},
         {:ok, :authorized} <- TripAuthorizer.authorize(trip, user),
         {:collated_facility_types, collated_trip_params} <-
           {:collated_facility_types,
            TripParams.collate_facility_types(trip_params, @valid_facility_types)},
         {:sanitized, sanitized_trip_params} <-
           {:sanitized, TripParams.sanitize_trip_params(collated_trip_params)},
         {:ok, %Trip{} = updated_trip} <- Trip.update(trip, sanitized_trip_params) do
      conn
      |> put_flash(:info, "Subscription updated.")
      |> render("edit.html", trip: updated_trip, changeset: Trip.update_changeset(updated_trip))
    else
      {:trip, nil} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :not_found}

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_flash(:error, "Trip could not be updated. Please see errors below.")
        |> render(
          "edit.html",
          trip: Trip.find_by_id(id),
          changeset: changeset,
          schedules: %{},
          return_schedules: %{}
        )
    end
  end

  def update(conn, %{"id" => id}) do
    # This function clause is here incase someone submits an update request
    # with no relevant days selected. In this scenario we want users to be
    # shown a message saying that they should at least select one relevant day.
    # This function's purpose is to trigger that error message.
    update(conn, %{"id" => id, "trip" => %{"relevant_days" => []}})
  end

  defp default_values(trip_params) do
    default_params = %{
      "routes" => [],
      "stops" => [],
      "elevator" => "false",
      "escalator" => "false",
      "relevant_days" => []
    }

    Map.merge(default_params, trip_params)
  end

  defp save_trip(%{valid?: false} = changeset, conn, _user) do
    conn
    |> put_flash(:error, "Please correct the error and re-submit.")
    |> render("new.html", %{changeset: changeset})
  end

  defp save_trip(changeset, conn, user) do
    trip = make_trip(changeset, user)

    subscriptions =
      make_stop_subscriptions(changeset, trip) ++ make_route_subscriptions(changeset, trip)

    multi = build_trip_transaction(trip, subscriptions, user)

    case Subscription.set_versioned_subscription(multi) do
      :ok ->
        conn
        |> put_flash(:info, "Success! Your subscription has been created.")
        |> redirect(to: trip_path(conn, :index))

      :error ->
        conn
        |> put_flash(:error, "There was an error creating your trip. Please try again.")
        |> render("new.html")
    end
  end

  defp build_trip_transaction(trip, subscriptions, user) do
    multi =
      Multi.run(Multi.new(), {:trip, 0}, fn _repo, _changes ->
        PaperTrail.insert(trip, originator: user, meta: %{owner: user.id})
      end)

    subscriptions
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {sub, index}, acc ->
      sub_to_insert =
        sub
        |> Map.merge(%{id: Ecto.UUID.generate(), rank: index})
        |> Subscription.create_changeset()

      acc
      |> Multi.run({:subscription, index}, fn _repo, _changes ->
        PaperTrail.insert(sub_to_insert, originator: user, meta: %{owner: user.id})
      end)
    end)
  end

  defp make_changeset(params \\ %{}) do
    types = %{
      relevant_days: {:array, :string},
      stops: {:array, :string},
      routes: {:array, :string},
      elevator: :string,
      escalator: :string
    }

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
    add_error(changeset, :relevant_days, "Please select at least one day to continue.")
  end

  defp validate_days(changeset), do: changeset

  defp validate_features(%{changes: %{elevator: "false", escalator: "false"}} = changeset) do
    add_error(changeset, :escalator, "Please select at least one station feature.")
  end

  defp validate_features(changeset), do: changeset

  defp validate_stops(%{changes: %{stops: [], routes: []}} = changeset) do
    add_error(changeset, :stops, "Please select a stop to continue.")
  end

  defp validate_stops(changeset), do: changeset

  defp validate_routes(%{changes: %{stops: [], routes: []}} = changeset) do
    add_error(changeset, :stops, "must choose at least one stop or line")
  end

  defp validate_routes(changeset), do: changeset

  defp make_trip(
         %{changes: %{relevant_days: relevant_days, elevator: elevator, escalator: escalator}},
         user
       ) do
    %Trip{
      id: Ecto.UUID.generate(),
      user_id: user.id,
      relevant_days: Enum.map(relevant_days, &String.to_existing_atom/1),
      start_time: ~T[03:20:00],
      end_time: ~T[01:50:00],
      facility_types:
        TripParams.input_to_facility_types(
          %{"elevator" => elevator, "escalator" => escalator},
          @valid_facility_types
        ),
      roundtrip: false,
      trip_type: :accessibility
    }
  end

  defp make_stop_subscriptions(%{changes: %{stops: stops}}, trip) do
    Enum.map(stops, fn stop ->
      trip
      |> make_subscription()
      |> Map.put(:origin, stop)
      |> Map.put(:destination, stop)
      |> Subscription.add_latlong_to_subscription(stop, stop)
    end)
  end

  defp make_route_subscriptions(%{changes: %{routes: routes}}, trip) do
    routes
    |> clean_routes_input()
    |> Enum.map(fn route ->
      route_type = if route == "Green", do: 0, else: 1

      trip
      |> make_subscription()
      |> Map.put(:route, route)
      |> Map.put(:route_type, route_type)
    end)
  end

  defp clean_routes_input(routes) do
    Enum.map(routes, fn route_input ->
      [route_name, _, _] = String.split(route_input, "~~")
      route_name
    end)
  end

  defp make_subscription(trip) do
    %Subscription{
      trip_id: trip.id,
      user_id: trip.user_id,
      relevant_days: trip.relevant_days,
      start_time: trip.start_time,
      end_time: trip.end_time,
      type: :accessibility,
      facility_types: trip.facility_types,
      return_trip: false
    }
  end

  defp message_if_paused(conn, %Trip{} = trip) do
    if Trip.paused?(trip) do
      put_flash(
        conn,
        :warning,
        [
          "This subscription is currently paused. You can resume alerts on your ",
          link("subscriptions", to: trip_path(conn, :index)),
          " page."
        ]
      )
    else
      conn
    end
  end
end
