defmodule ConciergeSite.Web.AuthControllerTest do
  use ConciergeSite.ConnCase

  import Test.Support.Helpers

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.User
  alias Ueberauth.Auth
  alias Ueberauth.Auth.{Credentials, Info}

  describe "GET /auth/:provider/register" do
    test "redirects to the OIDC registration page", %{conn: conn} do
      reassign_env(:concierge_site, :keyclooak_base_uri, "TEST-BASE-URI")
      reassign_env(:concierge_site, :keyclooak_client_id, "t-alerts")
      reassign_env(:concierge_site, :keyclooak_redirect_uri, "TEST-REDIRECT-URI")

      conn = get(conn, "/auth/keycloak/register")

      assert redirected_to(conn) =~
               ~r/.+\/auth\/realms\/MBTA\/protocol\/openid-connect\/registrations\?client_id=t-alerts&response_type=code&scope=openid&redirect_uri=.+/
    end
  end

  describe "GET /auth/:provider/callback" do
    setup do
      reassign_env(:concierge_site, ConciergeSite.Endpoint, authentication_source: "keycloak")

      reassign_env(:concierge_site, :token_verify_fn, fn _, _ ->
        {:ok, %{"resource_access" => %{"t-alerts" => %{"roles" => ["admin", "user"]}}}}
      end)

      rider =
        Repo.insert!(%User{
          email: "rider@example.com",
          phone_number: "5551234567",
          role: "user",
          encrypted_password: ""
        })

      {:ok, rider: rider}
    end

    test "given an ueberauth auth, logs the user into Guardian", %{
      conn: conn,
      rider: %User{id: id, email: email, phone_number: phone_number}
    } do
      conn =
        conn
        |> assign(:ueberauth_auth, auth_for(id, email, phone_number))
        |> get("/auth/keycloak/callback")

      assert %User{id: ^id, email: ^email, phone_number: ^phone_number} =
               Guardian.Plug.current_resource(conn)
    end

    test "given an ueberauth auth, redirects to the account options page (for an account with no trips)",
         %{conn: conn, rider: %User{id: id, email: email, phone_number: phone_number}} do
      conn =
        conn
        |> assign(:ueberauth_auth, auth_for(id, email, phone_number))
        |> get("/auth/keycloak/callback")

      assert redirected_to(conn) == "/account/options"
    end

    test "uses the email and phone number from the token in place of the database values as they might be more current if the user just updated their details in Keycloak",
         %{conn: conn, rider: %User{id: id}} do
      new_email = "newemail@example.com"
      new_phone_number = "+15559876543"
      new_role = "admin"

      # Uses the new phone number but strips the US country code to match our foramtting convention
      expected_phone_number = "5559876543"

      conn =
        conn
        |> assign(:ueberauth_auth, auth_for(id, new_email, new_phone_number))
        |> get("/auth/keycloak/callback")

      assert %User{
               id: ^id,
               email: ^new_email,
               phone_number: ^expected_phone_number,
               role: ^new_role
             } = Guardian.Plug.current_resource(conn)
    end

    test "creates user record if it doesn't already exist", %{conn: conn} do
      id = Ecto.UUID.generate()
      email = "new-user@mbta.com"
      phone_number = "+15556767676"

      conn
      |> assign(:ueberauth_auth, auth_for(id, email, phone_number))
      |> get("/auth/keycloak/callback")

      assert %User{email: "new-user@mbta.com", phone_number: "5556767676"} =
               User.for_email("new-user@mbta.com")
    end

    test "redirects to the landing page for an ueberauth failure", %{conn: conn} do
      reassign_env(:concierge_site, ConciergeSite.Endpoint, authentication_source: "local")

      conn =
        conn
        |> init_test_session(%{username: "test_username"})
        |> assign(:ueberauth_failure, "failed")
        |> get("/auth/keycloak/callback")

      assert redirected_to(conn) == "/"
    end
  end

  @spec auth_for(User.id(), String.t(), String.t() | nil) :: Auth.t()
  defp auth_for(id, email, phone_number) do
    %Auth{
      uid: email,
      provider: :keycloak,
      strategy: Ueberauth.Strategy.OIDC,
      info: %Info{
        name: "John Rider",
        email: email,
        phone: phone_number
      },
      credentials: %Credentials{
        token: "FAKE TOKEN",
        refresh_token: "FAKE REFRESH TOKEN",
        expires_at: System.system_time(:second) + 1_000,
        other: %{
          provider: :keycloak,
          user_info: %{
            "email" => email,
            "email_verified" => true,
            "family_name" => "Rider",
            "given_name" => "John",
            "mbta_uuid" => id,
            "name" => "John Rider",
            "phone" => phone_number,
            "preferred_username" => email
          }
        }
      }
    }
  end
end
