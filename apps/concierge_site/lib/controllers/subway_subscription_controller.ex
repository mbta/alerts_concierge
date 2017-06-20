defmodule ConciergeSite.SubwaySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.TemporaryState
  alias ConciergeSite.Subscriptions.SubwayLines
  alias AlertProcessor.ServiceInfoCache

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def info(conn, params, user, _claims) do
    subscription_params = Map.merge(params, %{user_id: user.id, route_type: 1})
    token = TemporaryState.encode(subscription_params)

    case ServiceInfoCache.get_subway_full_routes do
      {:ok, stations} ->
        station_list_select_options =
            SubwayLines.station_list_select_options(stations)

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
      params["subscription"], %{user_id: user.id, route_type: 1}
    )
    token = TemporaryState.encode(subscription_params)

    render conn, "preferences.html",
      token: token,
      subscription_params: subscription_params
  end
end
