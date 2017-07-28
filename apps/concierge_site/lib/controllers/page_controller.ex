defmodule ConciergeSite.PageController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    redirect(conn, to: subscription_path(conn, :index))
  end

  def account_disabled(conn, _params) do
    render(conn, "account_disabled.html")
  end
end
