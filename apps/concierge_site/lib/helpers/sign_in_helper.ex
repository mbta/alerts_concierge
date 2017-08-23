defmodule ConciergeSite.SignInHelper do
  @moduledoc """
  Common functions for user sign in with Guardian
  """

  import ConciergeSite.Router.Helpers
  import Phoenix.Controller, only: [redirect: 2]
  alias AlertProcessor.Model.User

  @doc """
  Signs in a user with Guardian and redirects based on the user's role and the
  route specified in options. Valid redirect options are :my_account and
  :default. By default admin users are redirected to the list of subscribers,
  and regular users are redirected to my subscriptions.
  """
  @spec sign_in(Plug.Conn.t, User.t, [redirect: atom]) :: Plug.Conn.t
  def sign_in(conn, user, redirect: :my_account) do
    conn
    |> sign_in_user(user)
    |> my_account_redirect(user)
  end

  def sign_in(conn, user, redirect: :default) do
    conn
    |> sign_in_user(user)
    |> default_redirect(user)
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

  defp my_account_redirect(conn, user) do
    if User.is_admin?(user) do
      redirect(conn, to: admin_my_account_path(conn, :edit))
    else
      redirect(conn, to: my_account_path(conn, :edit))
    end
  end

  defp default_redirect(conn, user) do
    if User.is_admin?(user) do
      redirect(conn, to: admin_subscriber_path(conn, :index))
    else
      redirect(conn, to: subscription_path(conn, :index))
    end
  end
end
