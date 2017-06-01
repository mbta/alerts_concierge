defmodule ConciergeSite.SubwaySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.TemporaryState
  alias AlertProcessor.ServiceInfoCache

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def info(conn, params, user, _claims) do
    subscription_params = Map.merge(params, %{user_id: user.id, route_type: 1})
    token = TemporaryState.encode(subscription_params)
    {:ok, stations} = ServiceInfoCache.get_subway_info
    
    render conn, "info.html",
      token: token,
      subscription_params: subscription_params,
      stations: stations
  end
end
