defmodule ConciergeSite.AccountView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.Model.User
  alias ConciergeSite.SessionHelper
  alias Ecto.Changeset
  alias Plug.Conn

  defdelegate keycloak_auth?, to: SessionHelper
  defdelegate email(user), to: User
  defdelegate phone_number(user), to: User

  def fetch_field!(changeset, field) do
    {_, value} = Changeset.fetch_field(changeset, field)
    value
  end

  def sms_frozen?(%{data: user}), do: User.inside_opt_out_freeze_window?(user)

  @spec format_phone_number(String.t()) :: String.t()
  def format_phone_number(
        <<area_code::binary-size(3), exchange::binary-size(3), extension::binary-size(4)>>
      ),
      do: "#{area_code}-#{exchange}-#{extension}"

  def format_phone_number(number), do: number

  @spec update_profile_url(Conn.t()) :: String.t()
  def update_profile_url(conn),
    do: keycloak_auth_action_url("MBTA_UPDATE_PROFILE", encoded_account_edit_url(conn))

  @spec edit_password_url(Conn.t()) :: String.t()
  def edit_password_url(conn),
    do: keycloak_auth_action_url("UPDATE_PASSWORD", encoded_account_edit_url(conn))

  @spec keycloak_auth_action_url(String.t(), String.t()) :: String.t()
  defp keycloak_auth_action_url(action, redirect_uri),
    do:
      "#{keycloak_base_uri()}/auth/realms/MBTA/protocol/openid-connect/auth?client_id=#{keycloak_client_id()}&kc_action=#{action}&response_type=code&redirect_uri=#{redirect_uri}"

  @spec keycloak_base_uri :: String.t()
  defp keycloak_base_uri, do: System.get_env("KEYCLOAK_BASE_URI")

  @spec keycloak_client_id :: String.t()
  defp keycloak_client_id, do: System.get_env("KEYCLOAK_CLIENT_ID")

  @spec encoded_account_edit_url(Conn.t()) :: String.t()
  defp encoded_account_edit_url(conn) do
    conn
    |> ConciergeSite.Router.Helpers.account_url(:edit)
    |> URI.encode()
  end
end
