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

  def breadcrumbs(%Plug.Conn{path_info: ["admin", path, endpoint, sub_endpoint]} = conn) do
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
  end
  def breadcrumbs(%Plug.Conn{path_info: ["admin", "my-account", _]}) do
    [%{title: "Admin Account", path: "/admin/my-account"}]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["admin", "subscription_search", endpoint]}) do
    [
      %{title: "Subscription Search", path: "/admin/subscription_search/#{endpoint}/new"},
      %{title: "Results", path: "#"}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["admin", path, endpoint]} = conn) do
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
      true ->
        [
          %{title: breadcrumb_title_parse(path), path: "/admin/#{path}"},
          %{title: breadcrumb_title_parse(endpoint), path: conn.request_path}
        ]
    end
  end
  def breadcrumbs(%Plug.Conn{path_info: ["login" | _]} = conn) do
    [%{title: "Sign In", path: conn.request_path}]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["reset-password" | _]} = conn) do
    [%{title: "Reset Password", path: conn.request_path}]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["intro"]} = conn) do
    [%{title: "Create Account", path: conn.request_path}]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["account" | _]} = conn) do
    [%{title: "Get Started", path: conn.request_path}]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["admin", path]} = conn) do
    [%{title: breadcrumb_title_parse(path), path: conn.request_path}]
  end
  def breadcrumbs(%Plug.Conn{path_info: [_path, _endpoint, _, "edit"]} = conn) do
    [%{title: "Edit Subscriptions", path: subscription_path(conn, :index)}]
  end
  def breadcrumbs(%Plug.Conn{path_info: [_path, _endpoint, "confirm_delete"]} = conn) do
    [
      %{title: "Edit Subscriptions", path: subscription_path(conn, :index)},
      %{title: "Confirm Delete Subscription", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["subscriptions", _endpoint, "new"]} = conn) do
    [
      %{title: "New Subscriptions", path: subscription_path(conn, :new)},
      %{title: "Trip Type", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["subscriptions", _endpoint, _, "info"]} = conn) do
    [
      %{title: "New Subscriptions", path: subscription_path(conn, :new)},
      %{title: "Trip Info", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["subscriptions", _endpoint, _, "train"]} = conn) do
    [
      %{title: "New Subscriptions", path: subscription_path(conn, :new)},
      %{title: "Trains", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["subscriptions", _endpoint, _, "ferry"]} = conn) do
    [
      %{title: "New Subscriptions", path: subscription_path(conn, :new)},
      %{title: "Ferries", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: ["subscriptions", _endpoint, _, "preferences"]} = conn) do
    [
      %{title: "New Subscriptions", path: subscription_path(conn, :new)},
      %{title: "Preferences", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: [path, "vacation", sub_endpoint]} = conn) do
    [
      %{title: breadcrumb_title_parse(path), path: "/#{path}/#{sub_endpoint}"},
      %{title: "Vacation", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: [path, _, _]} = conn) do
    [
      %{title: breadcrumb_title_parse(path), path: "/#{path}/edit"},
      %{title: "Change Password", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: [_path, "new"]} = conn) do
    [%{title: "New Subscriptions", path: conn.request_path}]
  end
  def breadcrumbs(%Plug.Conn{path_info: [path, "confirm_disable"]} = conn) do
    [
      %{title: breadcrumb_title_parse(path), path: "/#{path}/edit"},
      %{title: "Confirm Disable", path: conn.request_path}
    ]
  end
  def breadcrumbs(%Plug.Conn{path_info: [path, _]}) do
    [%{title: breadcrumb_title_parse(path), path: "/#{path}/edit"}]
  end
  def breadcrumbs(%Plug.Conn{}) do
    []
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
