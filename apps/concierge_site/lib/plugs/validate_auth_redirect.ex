defmodule ConciergeSite.Plugs.ValidateAuthRedirect do
  @moduledoc """
  Validates that custom auth redirects (used for the register page) are only
  going to the configured auth provider and nowhere else. This prevents an open
  redirect security vulnerability.
  """
  @behaviour Plug
  require Logger
  import Plug.Conn
  alias Plug.Conn

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Conn{query_params: %{"uri" => uri}} = conn, _opts) do
    base_uri = Application.get_env(:concierge_site, :keycloak_base_uri)

    if String.starts_with?(uri, base_uri) do
      conn
    else
      Logger.warning("Potentially malicious request: redirect_uri=#{uri}")
      send_resp(conn, :bad_request, "Bad redirect URI")
    end
  end

  def call(conn, _opts), do: conn
end
