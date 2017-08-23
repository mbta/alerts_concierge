defmodule ConciergeSite.CommuterRailSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{CommuterRailParams, Lines, TemporaryState}
  alias AlertProcessor.Model.{Subscription, User}
  alias AlertProcessor.{ServiceInfoCache, Subscription.CommuterRailMapper}

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def edit(conn, %{"id" => id}, user, _claims) do
    subscription = Subscription.one_for_user!(id, user.id, true)
    changeset = Subscription.create_changeset(subscription)
    {:ok, trips} = CommuterRailMapper.get_trip_info_from_subscription(subscription)
    render conn, "edit.html", subscription: subscription, changeset: changeset, trips: %{departure_trips: trips}
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}, user, {:ok, claims}) do
    subscription = Subscription.one_for_user!(id, user.id, true)
    with {:ok, params} <- CommuterRailParams.prepare_for_update_changeset(subscription, subscription_params),
         multi <- CommuterRailMapper.build_update_subscription_transaction(subscription, params, Map.get(claims, "imp", user.id)),
         :ok <- Subscription.set_versioned_subscription(multi) do
      :ok = User.clear_holding_queue_for_user_id(user.id)
      conn
      |> put_flash(:info, "Subscription updated.")
      |> redirect(to: subscription_path(conn, :index))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
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
      {:ok, trips} <- CommuterRailMapper.populate_trip_options(subscription_params) do
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

  def create(conn, params, user, {:ok, claims}) do
    commuter_rail_params = CommuterRailParams.prepare_for_mapper(params["subscription"])
    {:ok, subscription_infos} = CommuterRailMapper.map_subscriptions(commuter_rail_params)

    multi = CommuterRailMapper.build_subscription_transaction(subscription_infos, user, Map.get(claims, "imp", user.id))

    case Subscription.set_versioned_subscription(multi) do
      :ok ->
        redirect(conn, to: subscription_path(conn, :index))
      :error ->
        conn
        |> put_flash(:error, "There was an error saving the subscription. Please try again.")
        |> render("new.html")
    end
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
    {:ok, trips} = CommuterRailMapper.populate_trip_options(subscription_params)

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
    {:ok, trips} = CommuterRailMapper.get_trip_info_from_subscription(subscription)
    conn
    |> put_flash(:error, "Please select at least one trip")
    |> render("edit.html", subscription: subscription, changeset: changeset, trips: %{departure_trips: trips})
  end
end
