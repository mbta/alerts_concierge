defmodule ConciergeSite.AuthController do
  use ConciergeSite.Web, :controller

  require Logger

  alias AlertProcessor.Model.User
  alias AlertProcessor.Repo
  alias ConciergeSite.SessionHelper
  alias Plug.Conn

  plug(Ueberauth)

  @spec register(Conn.t(), map()) :: Conn.t()
  def register(conn, _params) do
    base_uri = System.get_env("KEYCLOAK_BASE_URI")
    client_id = System.get_env("KEYCLOAK_CLIENT_ID")
    redirect_uri = "KEYCLOAK_REDIRECT_URI" |> System.get_env() |> URI.encode()

    registration_uri =
      "#{base_uri}/auth/realms/MBTA/protocol/openid-connect/registrations?client_id=#{client_id}&response_type=code&scope=openid&redirect_uri=#{redirect_uri}"

    redirect(conn, external: registration_uri)
  end

  @spec callback(Conn.t(), any) :: Conn.t()
  def callback(
        %{
          assigns: %{
            ueberauth_auth: %{
              credentials: %{
                other: %{
                  user_info: %{"mbta_uuid" => id, "email" => email} = user_info
                }
              }
            }
          }
        } = conn,
        _params
      ) do
    phone_number =
      user_info
      |> Map.get("phone")
      |> strip_us_country_code()

    user =
      id
      |> get_or_create_user(email, phone_number)
      |> use_email_and_phone_from_token(email, phone_number)

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

  @spec get_or_create_user(User.id(), String.t(), String.t() | nil) :: User.t()
  defp get_or_create_user(id, email, phone_number) do
    case User.get(id) do
      nil ->
        Repo.insert!(%User{
          id: id,
          email: email,
          phone_number: phone_number,
          role: "user",
          encrypted_password: ""
        })

        User.get(id)

      user ->
        user
    end
  end

  # Display the email and phone number we received in the token rather than the values from the database.
  # In cases where the user just changed one of these fields in Keycloak, we might not have had time to update
  # the database yet, so the values in the token are more authoritative.
  @spec use_email_and_phone_from_token(User.t(), String.t(), String.t() | nil) :: User.t()
  defp use_email_and_phone_from_token(user, email, phone_number) do
    %User{
      user
      | email: email,
        phone_number: phone_number
    }
  end

  @spec strip_us_country_code(String.t() | nil) :: String.t() | nil
  defp strip_us_country_code("+1" <> phone_number), do: phone_number
  defp strip_us_country_code(phone_number), do: phone_number
end
