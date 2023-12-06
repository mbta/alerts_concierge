defmodule ConciergeSite.SessionHelper do
  @moduledoc "Common functions for user sign-in with Guardian."

  import ConciergeSite.Router.Helpers
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  alias AlertProcessor.Model.{Trip, User}
  alias Plug.Conn

  @endpoint ConciergeSite.Endpoint

  @doc "Signs in a user with Guardian and redirects to the appropriate route."
  @spec sign_in(Conn.t(), User.t()) :: Conn.t()
  def sign_in(conn, user, claims \\ %{}) do
    conn
    |> ConciergeSite.Guardian.Plug.sign_in(user, claims)
    |> redirect(to: sign_in_redirect_path(conn, user))
  end

  @spec sign_out(Conn.t()) :: Conn.t()
  @spec sign_out(Conn.t(), keyword()) :: Conn.t()
  def sign_out(conn, opts \\ []) do
    logout_uri = Conn.get_session(conn, "logout_uri")

    redirect_to =
      if Keyword.get(opts, :skip_oidc_sign_out, false) or is_nil(logout_uri) do
        [to: page_path(conn, :landing)]
      else
        [
          external: logout_uri
        ]
      end

    conn
    |> put_flash(:info, "You have been signed out.")
    |> Guardian.Plug.sign_out(ConciergeSite.Guardian)
    |> Conn.clear_session()
    |> redirect(redirect_to)
  end

  defp sign_in_redirect_path(conn, user)

  defp sign_in_redirect_path(%{path_info: ["auth", "keycloak_edit" | _]}, _user) do
    account_path(@endpoint, :edit)
  end

  defp sign_in_redirect_path(_conn, user) do
    if Trip.get_trips_by_user(user.id) == [] do
      account_path(@endpoint, :options_new)
    else
      trip_path(@endpoint, :index)
    end
  end
end
