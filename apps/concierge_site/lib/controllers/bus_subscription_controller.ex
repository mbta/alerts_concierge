defmodule ConciergeSite.BusSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.BusRoutes
  alias ConciergeSite.Subscriptions.TemporaryState
  alias AlertProcessor.ServiceInfoCache

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
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

    render conn, "preferences.html",
      token: token,
      subscription_params: subscription_params
  end
end
