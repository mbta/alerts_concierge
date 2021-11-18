defmodule ConciergeSite.SignInHelper do
  @moduledoc "Common functions for user sign-in with Guardian."

  import ConciergeSite.Router.Helpers
  import Phoenix.Controller, only: [redirect: 2]
  alias AlertProcessor.Model.{Trip, User}

  @endpoint ConciergeSite.Endpoint

  @doc "Signs in a user with Guardian and redirects to the appropriate route."
  @spec sign_in(Plug.Conn.t(), User.t()) :: Plug.Conn.t()
  def sign_in(conn, user) do
    conn
    |> Guardian.Plug.sign_in(user, :access, %{perms: permissions_for(user)})
    |> redirect(to: redirect_path(user))
  end

  @spec permissions_for(User.t()) :: map
  def permissions_for(%User{role: "admin"}) do
    %{
      default: Guardian.Permissions.max(),
      admin: Guardian.Permissions.max()
    }
  end

  def permissions_for(_user) do
    %{default: Guardian.Permissions.max()}
  end

  defp redirect_path(user) do
    if Trip.get_trips_by_user(user.id) == [] do
      account_path(@endpoint, :options_new)
    else
      trip_path(@endpoint, :index)
    end
  end
end
