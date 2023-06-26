defmodule ConciergeSite.AuthController do
  use ConciergeSite.Web, :controller

  require Logger

  alias AlertProcessor.Helpers.PhoneNumber
  alias AlertProcessor.Model.User
  alias AlertProcessor.Repo
  alias ConciergeSite.SessionHelper
  alias Ueberauth.Auth.Credentials
  alias Plug.Conn

  plug(Ueberauth)

  def register(conn, _params) do
    redirect(conn, to: "/auth/keycloak?" <> URI.encode_query(%{uri: registration_uri()}))
  end

  @spec callback(Conn.t(), any) :: Conn.t()
  def callback(
        %{
          assigns: %{
            ueberauth_auth: %{
              credentials:
                %{
                  other: %{
                    user_info: %{"mbta_uuid" => id, "email" => email} = user_info
                  }
                } = credentials
            }
          }
        } = conn,
        _params
      ) do
    phone_number =
      user_info
      |> Map.get("phone_number")
      |> PhoneNumber.strip_us_country_code()

    role = user_role(credentials)

    user =
      id
      |> get_or_create_user(email, phone_number, role)
      |> use_props_from_token(email, phone_number, role)

    SessionHelper.sign_in(conn, user)
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    Logger.info("Ueberauth failure: #{inspect(failure)}")
    SessionHelper.sign_out(conn)
  end

  def callback(%{assigns: assigns} = conn, params) do
    Logger.warn(
      "Unexpected Ueberauth callback assigns=#{inspect(assigns)} params=#{inspect(params)}"
    )

    SessionHelper.sign_out(conn)
  end

  @spec logout(Conn.t(), map()) :: Conn.t()
  def logout(conn, _params) do
    SessionHelper.sign_out(conn)
  end

  @spec get_or_create_user(User.id(), String.t(), String.t() | nil, String.t()) :: User.t()
  defp get_or_create_user(id, email, phone_number, role) do
    case User.get(id) do
      nil ->
        # The user just created their account in Keycloak so we need to add them to our database
        Repo.insert!(%User{
          id: id,
          email: email,
          phone_number: phone_number,
          role: role,
          encrypted_password: ""
        })

        User.get(id)

      user ->
        user
    end
  end

  # Display the email and phone number we received in the token rather than the
  # values from the database. We will eventually receive an SQS message from
  # Keycloak and update these values in our local database (so that we able
  # able to use them to send notifications), but in cases where the user just
  # changed one of these fields in Keycloak, we might not have had time receive
  # that message yet, so the values in the token are more authoritative.
  @spec use_props_from_token(User.t(), String.t(), String.t() | nil, String.t()) :: User.t()
  defp use_props_from_token(user, email, phone_number, role) do
    %User{
      user
      | email: email,
        phone_number: phone_number,
        role: role
    }
  end

  @spec user_role(Credentials.t()) :: String.t()
  defp user_role(%Credentials{
         token: token,
         other: %{
           provider: provider
         }
       }) do
    token_verify_fn =
      Application.get_env(:concierge_site, :token_verify_fn, &OpenIDConnect.verify/2)

    provider
    |> token_verify_fn.(token)
    |> parse_role()
  end

  # Parse the user's role from the access token provided by Keycloak
  @spec parse_role({:ok, map()} | {:error, :verify, any()}) :: String.t()
  defp parse_role({:ok, %{"resource_access" => %{"t-alerts" => %{"roles" => roles}}}}),
    do: highest_role(roles)

  defp parse_role(_), do: "user"

  @spec highest_role([String.t()]) :: String.t()
  defp highest_role(roles) when is_list(roles) do
    if Enum.member?(roles, "admin") do
      "admin"
    else
      "user"
    end
  end

  @spec registration_uri :: String.t()
  defp registration_uri do
    base_uri = Application.get_env(:concierge_site, :keycloak_base_uri)
    client_id = Application.get_env(:concierge_site, :keycloak_client_id)

    params = %{
      client_id: client_id,
      response_type: "code",
      scope: "openid"
    }

    build_uri("#{base_uri}/auth/realms/MBTA/protocol/openid-connect/registrations", params)
  end

  @spec build_uri(String.t(), map()) :: String.t()
  defp build_uri(uri, params) do
    query = URI.encode_query(params)

    uri
    |> URI.merge("?#{query}")
    |> URI.to_string()
  end
end
