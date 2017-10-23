defmodule ConciergeSite.BusSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{BusParams, BusRoutes, TemporaryState, SubscriptionParams}
  alias AlertProcessor.{Model.Subscription, Model.User, ServiceInfoCache, Subscription.BusMapper}

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def edit(conn, %{"id" => id}, user, _claims) do
    subscription = Subscription.one_for_user!(id, user.id, true)
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

  def create(conn, params, user, {:ok, claims}) do
    with subscription_params <- params["subscription"],
      mapper_params <- BusParams.prepare_for_mapper(subscription_params),
      {:ok, subscriptions} <- BusMapper.map_subscription(mapper_params),
      multi <- BusMapper.build_subscription_transaction(subscriptions, user, Map.get(claims, "imp", user.id)),
      :ok <- Subscription.set_versioned_subscription(multi) do
        redirect(conn, to: subscription_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "There was an error saving the subscription. Please try again.")
        |> render("new.html")
    end
  end

  def info(conn, params, user, _claims) do
    subscription_params = Map.merge(params, %{user_id: user.id, route_type: 3})
    token = TemporaryState.encode(subscription_params)

    case ServiceInfoCache.get_bus_info do
      {:ok, routes} ->
        route_list_select_options = BusRoutes.route_list_select_options(routes)

        subscription_params = Map.put(subscription_params, "routes", [])

        render conn, "info.html",
          token: token,
          subscription_params: subscription_params,
          route_list_select_options: route_list_select_options,
          selected_routes: []
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching route data. Please try again.")
        |> render("new.html", token: token, subscription_params: subscription_params)
    end
  end

  def preferences(conn, params, user, _claims) do
    subscription_params = params["subscription"]
    |> Map.merge(%{"user_id" => user.id, "route_type" => 3})

    token = TemporaryState.encode(subscription_params)

    with :ok <- BusParams.validate_info_params(subscription_params),
      route_ids <- subscription_params["routes"] |> Enum.map(& &1 |> String.split(" - ") |> List.first()) do
      routes =
        Enum.map(route_ids, fn(route_id) ->
          {:ok, route} = ServiceInfoCache.get_route(route_id)
          route
        end)

      render conn, "preferences.html",
        token: token,
        routes: routes,
        subscription_params: subscription_params
    else
      {:error, message} ->
        handle_error_info_submission(conn, subscription_params, token, message)
      _ ->
        handle_error_info_submission(conn, subscription_params, token, "Something went wrong, please try again.")
    end
  end

  defp handle_error_info_submission(conn, subscription_params, token, error_message) do
    case ServiceInfoCache.get_bus_info() do
      {:ok, routes} ->
        route_list_select_options = BusRoutes.route_list_select_options(routes)
        selected_routes =
          Enum.filter(route_list_select_options, fn({_, option_value}) ->
            Enum.member?(subscription_params["routes"], option_value)
          end)

        conn
        |> put_flash(:error, error_message)
        |> render(
          "info.html",
          token: token,
          subscription_params: subscription_params,
          route_list_select_options: route_list_select_options,
          selected_routes: selected_routes
        )
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching route data. Please try again.")
        |> render("new.html", token: token, subscription_params: subscription_params)
    end
  end
end
