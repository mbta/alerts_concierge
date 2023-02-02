defmodule Ueberauth.Strategy.FakeKeycloak do
  @moduledoc """
  A fake ueberauth strategy for development purposes.
  """
  use Ueberauth.Strategy, ignores_csrf_attack: true

  @impl Ueberauth.Strategy
  def handle_request!(conn) do
    conn
    |> redirect!("/auth/keycloak/callback")
    |> halt()
  end

  @impl Ueberauth.Strategy
  def handle_callback!(conn) do
    conn
  end

  @impl Ueberauth.Strategy
  def uid(_conn) do
    "fake_uid"
  end

  @impl Ueberauth.Strategy
  def credentials(conn) do
    %Ueberauth.Auth.Credentials{
      token: "fake_access_token",
      expires: true,
      expires_at: expires_at(conn),
      other: %{
        provider: :keycloak,
        user_info: %{
          "email" => "fake@example.com",
          "email_verified" => true,
          "family_name" => "Name",
          "given_name" => "Fake",
          "mbta_uuid" => "acad6280-8cb9-4e00-999c-c6d141adf0a6",
          "name" => "Fake Name",
          "phone" => "+15555555555",
          "preferred_username" => "fake@example.com",
          "sub" => "7eaf0809-88da-4895-97e0-c83444ab310f"
        }
      },
      refresh_token: nil,
      scopes: [],
      secret: nil,
      token_type: "Bearer"
    }
  end

  @impl Ueberauth.Strategy
  def info(_conn) do
    %Ueberauth.Auth.Info{}
  end

  @impl Ueberauth.Strategy
  def extra(conn) do
    %Ueberauth.Auth.Extra{
      raw_info: %{
        claims: %{
          "exp" => expires_at(conn)
        }
      }
    }
  end

  @impl Ueberauth.Strategy
  def handle_cleanup!(conn) do
    conn
  end

  # Support configuring a specific expiration_datetime for testing.
  # Otherwise, default to 9 hours from now.
  @spec expires_at() :: integer
  @spec expires_at(Plug.Conn.t()) :: integer
  defp expires_at(conn) do
    case expiration_datetime_from_session(conn) do
      nil ->
        expires_at()

      expiration_datetime ->
        DateTime.to_unix(expiration_datetime)
    end
  end

  defp expires_at do
    nine_hours_in_seconds = 9 * 60 * 60

    expiration_datetime = DateTime.add(DateTime.utc_now(), nine_hours_in_seconds)

    DateTime.to_unix(expiration_datetime)
  end

  @spec expiration_datetime_from_session(Plug.Conn.t()) :: any()
  defp expiration_datetime_from_session(conn) do
    conn
    |> fetch_session()
    |> get_session(:expiration_datetime)
  end
end
