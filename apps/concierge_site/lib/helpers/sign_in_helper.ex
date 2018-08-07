defmodule ConciergeSite.SignInHelper do
  @moduledoc """
  Common functions for user sign in with Guardian
  """

  import ConciergeSite.Router.Helpers
  import Phoenix.Controller, only: [redirect: 2]
  alias AlertProcessor.Model.User
  alias AlertProcessor.Model.Trip

  @endpoint ConciergeSite.Endpoint

  @doc """
  Signs in a user with Guardian and redirects based on the user's role and the
  route specified in options. Valid redirect options are :my_account, :default,
  and :admin_default. When logging in via /admin/login/new
  users are redirected to the list of subscribers,
  and when logging in via /login/new users are redirected to my subscriptions.
  When resetting password, admin users are redirected to admin my-account page
  and normal users are redirected to the base my-account page.
  """
  @spec sign_in(Plug.Conn.t(), User.t()) :: Plug.Conn.t()
  def sign_in(conn, user) do
    conn
    |> sign_in_user(user)
    |> redirect(to: redirect_path(user))
  end

  defp sign_in_user(conn, user) do
    Guardian.Plug.sign_in(conn, user, :access, %{
      perms: %{default: Guardian.Permissions.max()}
    })
  end

  defp redirect_path(user) do
    if Trip.get_trips_by_user(user.id) == [] do
      account_path(@endpoint, :options_new)
    else
      trip_path(@endpoint, :index)
    end
  end
end
