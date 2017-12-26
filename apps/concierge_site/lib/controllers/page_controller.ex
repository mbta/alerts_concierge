defmodule ConciergeSite.PageController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    redirect(conn, to: subscription_path(conn, :index))
  end

  def account_disabled(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_resp_header("refresh", "5;url=#{session_path(conn, :new)}")
    |> render("account_disabled.html")
  end
end
