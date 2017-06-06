defmodule ConciergeSite.BusSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.TemporaryState

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end
end
