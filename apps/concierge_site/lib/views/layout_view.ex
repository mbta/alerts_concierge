defmodule ConciergeSite.LayoutView do
  use ConciergeSite.Web, :view
  import AlertProcessor.Model.User, only: [is_admin?: 1, is_app_admin?: 1]

  def active_nav_class(conn, page_name) do
    case conn.path_info do
      ["admin", ^page_name, _user] -> "nav-active"
      ["admin", ^page_name] -> "nav-active"
      _ -> ""
    end
  end

  def breadcrumbs(conn) do
    case conn.path_info do
      ["admin", path, endpoint, sub_endpoint] ->
        cond do
          conn.assigns[:admin_user] ->
            [
              %{title: breadcrumb_title_parse(path), path: "/admin/#{path}"},
              %{title: conn.assigns[:admin_user].email, path: "/admin/#{path}/#{endpoint}"},
              %{title: breadcrumb_title_parse(sub_endpoint), path: conn.request_path}
            ]
          conn.assigns[:subscriber] ->
            [
              %{title: breadcrumb_title_parse(path), path: "/admin/#{path}"},
              %{title: conn.assigns[:subscriber].email, path: "/admin/#{path}/#{endpoint}"},
              %{title: breadcrumb_title_parse(sub_endpoint), path: conn.request_path}
            ]
          true ->
            [
              %{title: breadcrumb_title_parse(path), path: "/admin/#{path}"}
            ]
        end
      ["admin", path, endpoint] ->
        cond do
          conn.assigns[:subscriber] ->
            [
              %{title: "Subscribers", path: "/admin/subscribers"},
              %{title: conn.assigns[:subscriber].email, path: conn.request_path}
            ]
          conn.assigns[:admin_user] ->
            [
              %{title: breadcrumb_title_parse(path), path: "/admin/#{path}"},
              %{title: conn.assigns[:admin_user].email, path: conn.request_path}
            ]
          path == "my-account" ->
            [
              %{title: "Admin Account", path: "/admin/#{path}"}
            ]
          true ->
            [
              %{title: breadcrumb_title_parse(path), path: "/admin/#{path}"},
              %{title: breadcrumb_title_parse(endpoint), path: conn.request_path}
            ]
        end
      ["admin", path] ->
        [%{title: breadcrumb_title_parse(path), path: conn.request_path}]
      [path, endpoint, _, sub_endpoint] ->
        cond do
          sub_endpoint == "preferences" ->
            [%{title: "New Subscriptions", path: "/#{path}/new"},
            %{title: "Trip Type", path: "/#{path}/#{endpoint}/new"},
            %{title: "Trip Info", path: "/#{path}/#{endpoint}/new/info?trip_type=one_way"},
            %{title: "Preferences", path: conn.request_path}]
          sub_endpoint == "edit" ->
            [%{title: "Edit Subscriptions", path: "/my-subscriptions"}]
          true ->
            [%{title: "New Subscriptions", path: "/#{path}/new"},
            %{title: "Trip Type", path: "/#{path}/#{endpoint}/new"},
            %{title: "Trip Info", path: "/#{path}/#{endpoint}/new/info?trip_type=one_way"}]
        end
      [path, endpoint, sub_endpoint] ->
        cond do
          sub_endpoint == "confirm_delete" ->
            [%{title: "Edit Subscriptions", path: "/my-subscriptions"},
            %{title: "Confirm Delete Subscription", path: conn.request_path}]
          sub_endpoint == "new" ->
            [%{title: "New Subscriptions", path: "/#{path}/#{sub_endpoint}"},
            %{title: "Trip Type", path: conn.request_path}]
          endpoint == "vacation" ->
            [%{title: breadcrumb_title_parse(path), path: "/#{path}/#{sub_endpoint}"},
             %{title: breadcrumb_title_parse(endpoint), path: conn.request_path}]
          true ->
            [%{title: breadcrumb_title_parse(path), path: "/#{path}/edit"},
            %{title: "Change Password", path: conn.request_path}]
        end
      [path, endpoint] ->
        cond do
          endpoint == "new" ->
            [%{title: "New Subscriptions", path: conn.request_path}]
          endpoint == "confirm_disable" ->
            [%{title: breadcrumb_title_parse(path), path: "/#{path}/edit"},
            %{title: breadcrumb_title_parse(endpoint), path: conn.request_path}]
          true ->
            [%{title: breadcrumb_title_parse(path), path: "/#{path}/edit"}]
        end
      _ ->
        []
    end
  end

  defp breadcrumb_title_parse(endpoint) do
    endpoint
      |> String.split(["_", "-"])
      |> Enum.map(&(String.capitalize(&1)))
      |> Enum.join(" ")
  end

  def impersonation_banner(conn, impersonated_user) do
    case Guardian.Plug.claims(conn) do
      {:ok, %{"imp" => _admin_id}} ->
        content_tag :div, class: "callout-active impersonation-callout" do
          ["You are logged in on behalf of #{impersonated_user.email}.",
           link("Sign Out and Return to MBTA Admin",
             to: impersonate_session_path(conn, :delete), method: :delete)]
        end
      _ -> nil
    end
  end
end
