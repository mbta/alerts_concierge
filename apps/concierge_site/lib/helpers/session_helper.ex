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
    |> redirect(to: sign_in_redirect_path(user))
  end

  @spec sign_out(Conn.t()) :: Conn.t()
  def sign_out(conn) do
    redirect_to =
      if keycloak_auth?() do
        id_token = conn |> Guardian.Plug.current_claims() |> Map.get("id_token")

        [
          external:
            URI.encode(
              "#{System.get_env("KEYCLOAK_LOGOUT_URI")}?post_logout_redirect_uri=#{page_url(conn, :landing)}&id_token_hint=#{id_token}"
            )
        ]
      else
        [to: page_path(conn, :landing)]
      end

    conn
    |> put_flash(:info, "You have been signed out.")
    |> Guardian.Plug.sign_out(ConciergeSite.Guardian)
    |> Conn.clear_session()
    |> redirect(redirect_to)
  end

  @spec keycloak_auth? :: boolean()
  def keycloak_auth? do
    Application.get_env(:concierge_site, ConciergeSite.Endpoint)[:authentication_source] ==
      "keycloak"
  end

  defp sign_in_redirect_path(user) do
    if Trip.get_trips_by_user(user.id) == [] do
      account_path(@endpoint, :options_new)
    else
      trip_path(@endpoint, :index)
    end
  end
end
