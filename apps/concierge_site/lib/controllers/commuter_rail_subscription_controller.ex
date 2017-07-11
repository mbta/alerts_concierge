defmodule ConciergeSite.CommuterRailSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{CommuterRailParams, Lines, TemporaryState}
  alias AlertProcessor.Model.{InformedEntity, Subscription}
  alias AlertProcessor.{Helpers.DateTimeHelper, Repo, ServiceInfoCache, Subscription.CommuterRailMapper}

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def edit(conn, %{"id" => id}, user, _claims) do
    subscription = Subscription.one_for_user!(id, user.id, true)
    changeset = Subscription.create_changeset(subscription)
    {:ok, {_name, origin_id}} = ServiceInfoCache.get_stop_by_name(subscription.origin)
    {:ok, {_name, destination_id}} = ServiceInfoCache.get_stop_by_name(subscription.destination)
    [relevant_days] = subscription.relevant_days
    selected_trips =
      subscription.informed_entities
      |> Enum.filter(fn(informed_entity) ->
           InformedEntity.entity_type(informed_entity) == :trip
         end)
      |> Enum.map(& &1.trip)
    {:ok, trips} = get_trip_info(origin_id, destination_id, relevant_days, selected_trips)
    render conn, "edit.html", subscription: subscription, changeset: changeset, trips: %{departure_trips: trips}
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}, user, _claims) do
    subscription = Subscription.one_for_user!(id, user.id, true)
    with {:ok, params} <- CommuterRailParams.prepare_for_update_changeset(subscription, subscription_params),
         multi <- CommuterRailMapper.build_update_subscription_transaction(subscription, params),
         {:ok, _subscription} <- Repo.transaction(multi) do
      conn
      |> put_flash(:info, "Subscription updated.")
      |> redirect(to: subscription_path(conn, :index))
    else
      {:error, changeset} ->
        handle_invalid_update_submission(conn, subscription, changeset)
      _ ->
        changeset = Subscription.create_changeset(subscription)
        handle_invalid_update_submission(conn, subscription, changeset)
    end
  end

  def info(conn, params, user, _claims) do
    subscription_params = Map.merge(params, %{"user_id" => user.id, "route_type" => 2})
    token = TemporaryState.encode(subscription_params)

    case ServiceInfoCache.get_commuter_rail_info do
      {:ok, stations} ->
        station_list_select_options =
          Lines.station_list_select_options(stations)

        render conn, "info.html",
          token: token,
          subscription_params: subscription_params,
          station_list_select_options: station_list_select_options
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> render("new.html", token: token, subscription_params: subscription_params)
    end
  end

  def train(conn, params, user, _claims) do
    subscription_params = Map.merge(
      params["subscription"], %{"user_id" => user.id, "route_type" => 2}
    )
    token = TemporaryState.encode(subscription_params)

    with :ok <- CommuterRailParams.validate_info_params(subscription_params),
      {:ok, trips} <- populate_trip_options(subscription_params) do
      render conn, "train.html",
        token: token,
        subscription_params: subscription_params,
        trips: trips
    else
      {:error, message} ->
        handle_invalid_info_submission(conn, subscription_params, token, message)
    end
  end

  def preferences(conn, params, user, _claims) do
    subscription_params = Map.merge(
      params["subscription"], %{"user_id" => user.id, "route_type" => 2}
    )
    token = TemporaryState.encode(subscription_params)

    with :ok <- CommuterRailParams.validate_trip_params(subscription_params),
         {:ok, origin} <- ServiceInfoCache.get_stop(subscription_params["origin"]),
         {:ok, destination} <- ServiceInfoCache.get_stop(subscription_params["destination"]) do
      render conn, "preferences.html",
        token: token,
        subscription_params: subscription_params,
        origin: origin,
        destination: destination
    else
      {:error, message} ->
        handle_invalid_trip_submission(conn, subscription_params, token, message)
      _ ->
        handle_invalid_trip_submission(conn, subscription_params, token, "Something went wrong, please try again.")
    end
  end

  def create(conn, params, user, _claims) do
    subway_params = CommuterRailParams.prepare_for_mapper(params["subscription"])
    {:ok, subscription_infos} = CommuterRailMapper.map_subscriptions(subway_params)

    multi = CommuterRailMapper.build_subscription_transaction(subscription_infos, user)

    case Repo.transaction(multi) do
      {:ok, _} ->
        redirect(conn, to: subscription_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, "There was an error saving the subscription. Please try again.")
        |> render("new.html")
    end
  end

  defp populate_trip_options(%{"trip_type" => "one_way"} = subscription_params) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days, "departure_start" => ds} = subscription_params
    case get_trip_info(origin, destination, relevant_days, ds) do
      {:ok, trips} ->
        {:ok, %{departure_trips: trips}}
      :error ->
        {:error, "Please correct the following errors to proceed: Please select a valid origin and destination combination."}
    end
  end
  defp populate_trip_options(%{"trip_type" => "round_trip"} = subscription_params) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days, "departure_start" => ds, "return_start" => rs} = subscription_params
    with {:ok, departure_trips} <- get_trip_info(origin, destination, relevant_days, ds),
         {:ok, return_trips} <- get_trip_info(destination, origin, relevant_days, rs) do
      {:ok, %{departure_trips: departure_trips, return_trips: return_trips}}
    else
      _ -> {:error, "Please correct the following errors to proceed: Please select a valid origin and destination combination."}
    end
  end

  defp get_trip_info(origin, destination, relevant_days, slected_trip_numbers) when is_list(slected_trip_numbers) do
    case CommuterRailMapper.map_trip_options(origin, destination, relevant_days) do
      {:ok, trips} ->
        updated_trips =
          for trip <- trips do
            if Enum.member?(slected_trip_numbers, trip.trip_number) do
              %{trip | selected: true}
            else
              %{trip | selected: false}
            end
          end
        {:ok, updated_trips}
      _ ->
        :error
    end
  end
  defp get_trip_info(origin, destination, relevant_days, timestamp) do
    case CommuterRailMapper.map_trip_options(origin, destination, String.to_existing_atom(relevant_days)) do
      {:ok, trips} ->
        departure_start = timestamp |> Time.from_iso8601!() |> DateTimeHelper.seconds_of_day()
        closest_trip = Enum.min_by(trips, &calculate_difference(&1, departure_start))
        updated_trips =
          for trip <- trips do
            if trip.trip_number == closest_trip.trip_number do
              %{trip | selected: true}
            else
              %{trip | selected: false}
            end
          end
        {:ok, updated_trips}
      _ ->
        :error
    end
  end

  defp calculate_difference(trip, departure_start) do
    departure_time = DateTimeHelper.seconds_of_day(trip.departure_time)
    abs(departure_start - departure_time)
  end

  defp handle_invalid_info_submission(conn, subscription_params, token, error_message) do
    case ServiceInfoCache.get_commuter_rail_info do
      {:ok, stations} ->
        station_list_select_options =
          Lines.station_list_select_options(stations)

        conn
        |> put_flash(:error, error_message)
        |> render(
          "info.html",
          token: token,
          subscription_params: subscription_params,
          station_list_select_options: station_list_select_options
        )
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> render("new.html", token: token, subscription_params: subscription_params)
    end
  end

  def handle_invalid_trip_submission(conn, subscription_params, token, error_message) do
    {:ok, trips} = populate_trip_options(subscription_params)

    conn
    |> put_flash(:error, error_message)
    |> render(
      "train.html",
      token: token,
      subscription_params: Map.drop(subscription_params, ["trips", "return_trips"]),
      trips: trips
    )
  end

  def handle_invalid_update_submission(conn, subscription, changeset) do
    {:ok, {_name, origin_id}} = ServiceInfoCache.get_stop_by_name(subscription.origin)
    {:ok, {_name, destination_id}} = ServiceInfoCache.get_stop_by_name(subscription.destination)
    [relevant_days] = subscription.relevant_days
    selected_trips =
      subscription.informed_entities
      |> Enum.filter(fn(informed_entity) ->
        InformedEntity.entity_type(informed_entity) == :trip
      end)
      |> Enum.map(& &1.trip)
    {:ok, trips} = get_trip_info(origin_id, destination_id, relevant_days, selected_trips)
    conn
    |> put_flash(:error, "Please select at least one trip")
    |> render("edit.html", subscription: subscription, changeset: changeset, trips: %{departure_trips: trips})
  end
end
