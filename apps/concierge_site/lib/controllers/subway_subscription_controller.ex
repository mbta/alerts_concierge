defmodule ConciergeSite.SubwaySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end
end
