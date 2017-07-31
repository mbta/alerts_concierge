defmodule ConciergeSite.Admin.SubscriberController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  def index(conn, _params, _user, _claims) do
    render conn, "index.html"
  end
end
