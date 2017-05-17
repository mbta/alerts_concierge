defmodule ConciergeSite.SubscriptionController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
