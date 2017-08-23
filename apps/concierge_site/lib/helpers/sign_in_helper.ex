defmodule ConciergeSite.SignInHelper do
  @moduledoc """
  Common functions for user sign in with Guardian
  """

  import ConciergeSite.Router.Helpers
  import Phoenix.Controller, only: [redirect: 2]
  alias AlertProcessor.Model.User

  @endpoint ConciergeSite.Endpoint

  @doc """
  Signs in a user with Guardian and redirects based on the user's role and the
  route specified in options. Valid redirect options are :my_account and
  :default. By default admin users are redirected to the list of subscribers,
  and regular users are redirected to my subscriptions.
  """
  @spec sign_in(Plug.Conn.t, User.t, [redirect: atom]) :: Plug.Conn.t
  def sign_in(conn, user, opts) do
    conn
    |> sign_in_user(user)
    |> redirect(to: redirect_path(user, Keyword.get(opts, :redirect, :default)))
  end

  defp sign_in_user(conn, %User{role: "customer_support"} = user) do
    Guardian.Plug.sign_in(conn, user, :token, perms: %{
      default: Guardian.Permissions.max,
      admin: [:customer_support]
    })
  end

  defp sign_in_user(conn, %User{role: "application_administration"} = user) do
    Guardian.Plug.sign_in(conn, user, :token,
      perms: %{
        default: Guardian.Permissions.max,
        admin: [:customer_support, :application_administration]
    })
  end

  defp sign_in_user(conn, user) do
    Guardian.Plug.sign_in(conn, user, :access,
      perms: %{default: Guardian.Permissions.max})
  end

  defp redirect_path(user, :default) do
    if User.is_admin?(user) do
      admin_subscriber_path(@endpoint, :index)
    else
      subscription_path(@endpoint, :index)
    end
  end

  defp redirect_path(user, :my_account) do
    if User.is_admin?(user) do
      admin_my_account_path(@endpoint, :edit)
    else
      my_account_path(@endpoint, :edit)
    end
  end
end
