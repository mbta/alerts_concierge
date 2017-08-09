defmodule ConciergeSite.LayoutView do
  use ConciergeSite.Web, :view

  def admin_user(conn), do: Guardian.Plug.current_resource(conn)
  def admin_user?(conn), do: admin_user(conn).role in ~w(application_administration customer_support)
  def admin_logged_in?(conn), do: Guardian.Plug.authenticated?(conn) && admin_user?(conn)
end
