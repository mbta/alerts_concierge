defmodule ConciergeSite.BusSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{BusParams, BusRoutes, TemporaryState}
  alias AlertProcessor.{Repo, ServiceInfoCache, Subscription.BusMapper}
  alias Ecto.Multi

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def create(conn, params, user, _claims) do
    mapper_params = put_in(params["subscription"]["relevant_days"], relevant_days(params["subscription"]))

    case BusMapper.map_subscription(mapper_params["subscription"]) do
      {:ok, subscriptions, informed_entities} ->
        multi = build_subscription_transaction(subscriptions, informed_entities, user)

        case Repo.transaction(multi) do
          {:ok, _} ->
            redirect(conn, to: subscription_path(conn, :index))
          {:error, _, _, _} ->
            handle_error_info_submission(conn, params["subscription"], user)
        end
      :error ->
        handle_error_info_submission(conn, params, user)
    end
  end

  defp build_subscription_transaction(subscriptions, informed_entities, user) do
    subscriptions
    |> Enum.with_index
    |> Enum.reduce(Multi.new, fn({sub, index}, acc) ->
      sub_to_insert = Map.merge(sub,
        %{user_id: user.id, informed_entities: informed_entities})

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

  defp relevant_days(params) do
    for {day, value} <- Map.take(params, ~w(saturday sunday weekday)),
      value == "true" do
      day
    end
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
    subscription_params = Map.merge(
      params["subscription"], %{user_id: user.id, route_type: 3}
    )
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
