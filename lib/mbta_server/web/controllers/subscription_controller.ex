defmodule MbtaServer.Web.SubscriptionController do
  use MbtaServer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
