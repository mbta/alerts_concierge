defmodule ConciergeSite.SessionController do
  use ConciergeSite.Web, :controller
  alias ConciergeSite.SessionHelper
  plug(:scrub_params, "user" when action in [:create])

  def new(conn, _params) do
    redirect(conn, to: "/auth/keycloak")
  end

  def delete(conn, _params) do
    SessionHelper.sign_out(conn)
  end

  # this path has changed, so add a redirect incase anyone had bookmarked
  def login_redirect(conn, _params), do: redirect(conn, to: "/login/new")
end
