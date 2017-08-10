defmodule ConciergeSite.LayoutView do
  use ConciergeSite.Web, :view

  def admin_user?(nil), do: false
  def admin_user?(user), do: user.role in ~w(application_administration customer_support)

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
      ["admin", endpoint, _] ->
        [%{title: breadcrumb_title_parse(endpoint), path: "/admin/#{endpoint}"}]
      ["admin", endpoint] ->
        [%{title: breadcrumb_title_parse(endpoint), path: conn.request_path}]
      _ ->
        []
    end
  end

  defp breadcrumb_title_parse(endpoint) do
    endpoint
      |> String.split("_")
      |> Enum.map(&(String.capitalize(&1)))
      |> Enum.join(" ")
  end
end
