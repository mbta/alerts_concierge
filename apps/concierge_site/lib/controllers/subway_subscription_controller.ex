defmodule ConciergeSite.SubwaySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.TemporaryState
  alias ConciergeSite.Subscriptions.Lines
  alias ConciergeSite.Subscriptions.SubwayParams
  alias ConciergeSite.Subscriptions.SubscriptionParams
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Subscription.SubwayMapper
  alias AlertProcessor.Model.Subscription
  alias AlertProcessor.Model.User

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def edit(conn, %{"id" => id}, user, _claims) do
    subscription = Subscription.one_for_user!(id, user.id)
    changeset = Subscription.create_changeset(subscription)
    render conn, "edit.html", subscription: subscription, changeset: changeset
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}, user, {:ok, claims}) do
    subscription = Subscription.one_for_user!(id, user.id, true)
    with {:ok, params} <- SubscriptionParams.prepare_for_update_changeset(subscription_params),
         {:ok, _subscription} <- Subscription.update_subscription(subscription, params, Map.get(claims, "imp", user.id)) do
      :ok = User.clear_holding_queue_for_user_id(user.id)
      conn
      |> put_flash(:info, "Subscription updated.")
      |> redirect(to: subscription_path(conn, :index))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Subscription could not be updated. Please see errors below.")
        |> render("edit.html", subscription: subscription, changeset: changeset)
      {:error, error_message} ->
        changeset = Subscription.create_changeset(subscription)
        conn
        |> put_flash(:error, error_message)
        |> render("edit.html", subscription: subscription, changeset: changeset)
    end
  end

  def info(conn, params, user, _claims) do
    subscription_params = Map.merge(params, %{"user_id" => user.id, "route_type" => 1})
    token = TemporaryState.encode(subscription_params)

    case ServiceInfoCache.get_subway_full_routes do
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

  def preferences(conn, params, user, _claims) do
    subscription_params = Map.merge(
      params["subscription"], %{"user_id" => user.id, "route_type" => 1}
    )
    token = TemporaryState.encode(subscription_params)

    case SubwayParams.validate_info_params(subscription_params) do
      :ok ->
        station_names =
          subscription_params
          |> Map.take(~w(origin destination))
          |> Lines.subway_station_names_from_ids()
        render conn, "preferences.html",
          token: token,
          subscription_params: subscription_params,
          station_names: station_names
      {:error, message} ->
        handle_invalid_info_submission(conn, subscription_params, token, message)
    end
  end

  def create(conn, params, user, {:ok, claims}) do
    subway_params = SubwayParams.prepare_for_mapper(params["subscription"])
    {:ok, subscription_infos} = SubwayMapper.map_subscriptions(subway_params)

    multi = SubwayMapper.build_subscription_transaction(subscription_infos, user, Map.get(claims, "imp", user.id))

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
    case ServiceInfoCache.get_subway_full_routes do
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
end
