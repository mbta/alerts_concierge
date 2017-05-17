defmodule ConciergeSite.SubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  def index(conn, _params, _user, _claims) do
    render conn, "index.html"
  end

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def type(conn, _params, _user, _claims) do
    render conn, "type.html"
  end
end
