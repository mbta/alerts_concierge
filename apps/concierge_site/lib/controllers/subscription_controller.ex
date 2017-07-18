defmodule ConciergeSite.SubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  alias AlertProcessor.Model.Subscription

  def index(conn, _params, user, _claims) do
    case Subscription.for_user(user) do
      [] -> redirect(conn, to: subscription_path(conn, :new))
      subscriptions ->
        {:ok, departure_time_map} = ConciergeSite.Subscriptions.DisplayInfo.departure_times_for_subscriptions(subscriptions)

        render conn, "index.html", subscriptions: subscriptions, departure_time_map: departure_time_map
    end
  end

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def edit(conn, _params, _user, _claims) do
    render conn, "edit.html"
  end
end
