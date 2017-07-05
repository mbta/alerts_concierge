defmodule ConciergeSite.BusSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{BusParams, BusRoutes, TemporaryState, SubscriptionParams}
  alias AlertProcessor.{Model.Subscription, Repo, ServiceInfoCache, Subscription.BusMapper}
  alias Ecto.Multi

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def edit(conn, %{"id" => id}, user, _claims) do
    subscription = Subscription.one_for_user!(id, user.id)
    changeset = Subscription.create_changeset(subscription)
    render conn, "edit.html", subscription: subscription, changeset: changeset
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}, user, _claims) do
    subscription = Subscription.one_for_user!(id, user.id)
    params = SubscriptionParams.prepare_for_update_changeset(subscription_params)
    changeset = Subscription.update_changeset(subscription, params)

    case Repo.update(changeset) do
      {:ok, _subscription} ->
        conn
        |> put_flash(:info, "Subscription updated.")
        |> redirect(to: subscription_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Subscription could not be updated. Please see errors below.")
        |> render("edit.html", subscription: subscription, changeset: changeset)
    end
  end

  def create(conn, params, user, _claims) do
    with subscription_params <- params["subscription"],
      mapper_params <- BusParams.prepare_for_mapper(subscription_params),
      {:ok, subscriptions} <- BusMapper.map_subscription(mapper_params),
      multi <- build_subscription_transaction(subscriptions, user),
      {:ok, _} <- Repo.transaction(multi) do
        redirect(conn, to: subscription_path(conn, :index))
    else
      _ -> handle_error_info_submission(conn, params["subscription"], user)
    end
  end

  defp build_subscription_transaction(subscriptions, user) do
    subscriptions
    |> Enum.with_index
    |> Enum.reduce(Multi.new, fn({{sub, ies}, index}, acc) ->
      sub_to_insert = sub
      |> Map.merge(%{
        user_id: user.id,
        informed_entities: ies
      })
      |> Subscription.create_changeset()

      acc
      |> Multi.insert({:subscription, index}, sub_to_insert)
    end)
  end

  defp handle_error_info_submission(conn, params, user) do
    subscription_params = Map.merge(params, %{user_id: user.id, route_type: 3})
    token = TemporaryState.encode(subscription_params)
    conn
    |> put_flash(:error, "There was an error creating your subscription. Please try again.")
    |> render("new.html", token: token, subscription_params: subscription_params)
  end

  def info(conn, params, user, _claims) do
    subscription_params = Map.merge(params, %{user_id: user.id, route_type: 3})
    token = TemporaryState.encode(subscription_params)

    case ServiceInfoCache.get_bus_info do
      {:ok, routes} ->
        route_list_select_options = BusRoutes.route_list_select_options(routes)

        render conn, "info.html",
          token: token,
          subscription_params: subscription_params,
          route_list_select_options: route_list_select_options
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

    case BusParams.validate_info_params(subscription_params) do
      :ok ->
        render conn, "preferences.html",
          token: token,
          subscription_params: subscription_params
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render("new.html", token: token, subscription_params: subscription_params)
    end
  end
end
