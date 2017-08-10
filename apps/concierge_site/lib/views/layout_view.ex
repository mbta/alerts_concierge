defmodule ConciergeSite.LayoutView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.User

  def admin_user(conn), do: Guardian.Plug.current_resource(conn)
  def admin_user?(conn), do: admin_user(conn).role in ~w(application_administration customer_support)
  def admin_logged_in?(conn), do: Guardian.Plug.authenticated?(conn) && admin_user?(conn)

  def active_nav_class(conn, page_name) do
    case conn.path_info do
      ["admin", endpoint, _user] when endpoint == page_name ->
        "nav-active"
      ["admin", endpoint] when endpoint == page_name ->
        "nav-active"
      _ ->
        ""
    end
  end

  def breadcrumbs(conn) do
    case conn.path_info do
      ["admin", endpoint, user_id] ->
        [%{title: breadcrumb_title_parse(endpoint), path: "/admin/#{endpoint}"},
         %{title: Repo.get(User, user_id).email, path: conn.request_path}]
      ["admin", endpoint] ->
        [%{title: breadcrumb_title_parse(endpoint), path: conn.request_path}]
      _ ->
        ""
    end
  end

  def breadcrumb_title_parse(endpoint) do
    endpoint
      |> String.split("_")
      |> Enum.map(&(String.capitalize(&1)))
      |> Enum.join(" ")
  end
end
