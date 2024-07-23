defmodule ConciergeSite.Web.AuthControllerTest do
  use ConciergeSite.ConnCase

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.User
  alias Ueberauth.Auth
  alias Ueberauth.Auth.{Credentials, Extra, Info}

  describe "GET /auth/:provider/callback" do
    setup %{conn: conn} do
      rider =
        Repo.insert!(%User{
          email: "rider@example.com",
          phone_number: "5551234567",
          role: "user"
        })

      {:ok, conn: conn, rider: rider}
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

      assert is_binary(Plug.Conn.get_session(conn, "logout_uri"))
    end

    test "given an ueberauth auth, redirects to the account options page (for an account with no trips)",
         %{conn: conn, rider: %User{id: id, email: email, phone_number: phone_number}} do
      conn =
        conn
        |> assign(:ueberauth_auth, auth_for(id, email, phone_number))
        |> get("/auth/keycloak/callback")

      assert redirected_to(conn) == "/account/options"
    end

    test "uses the email, phone number, and role from the token in place of the database values as they might be more current if the user just updated their details in Keycloak",
         %{conn: conn, rider: %User{id: id}} do
      new_email = "newemail@example.com"
      new_phone_number = "+15559876543"
      new_role = "admin"

      # Uses the new phone number but strips the US country code to match our foramtting convention
      expected_phone_number = "5559876543"

      conn =
        conn
        |> assign(:ueberauth_auth, auth_for(id, new_email, new_phone_number, [new_role]))
        |> get("/auth/keycloak/callback")

      assert %User{
               id: ^id,
               email: ^new_email,
               phone_number: ^expected_phone_number,
               role: ^new_role
             } = Guardian.Plug.current_resource(conn)
    end

    test "can use mbta_uuid user",
         %{conn: conn, rider: %User{id: id, email: email, phone_number: phone_number}} do
      auth = auth_for_user_with_mbta_uuid(nil, email, phone_number, ["user"], id)

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get("/auth/keycloak/callback")

      assert %User{id: ^id, email: ^email, phone_number: ^phone_number} =
               Guardian.Plug.current_resource(conn)
    end

    @tag capture_log: true
    test "redirects if we somehow get 2 users",
         %{conn: conn, rider: %User{id: id, email: email, phone_number: phone_number}} do
      user2 =
        Repo.insert!(%User{
          email: "rider2@example.com",
          phone_number: "5551234567",
          role: "user"
        })

      auth = auth_for_user_with_mbta_uuid(id, email, phone_number, ["user"], user2.id)

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get("/auth/keycloak/callback")

      assert is_nil(Guardian.Plug.current_resource(conn))
      assert redirected_to(conn) == "/"
    end

    test "doesn't allow admin access if the token says they are now just a user",
         %{conn: conn} do
      was_an_admin =
        Repo.insert!(%User{
          email: "was_an_admin@example.com",
          role: "admin"
        })

      conn =
        conn
        |> assign(
          :ueberauth_auth,
          auth_for(was_an_admin.id, was_an_admin.email, was_an_admin.phone_number, ["user"])
        )
        |> get("/auth/keycloak/callback")

      assert user = Guardian.Plug.current_resource(conn)
      refute User.admin?(user)
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
      conn =
        conn
        |> init_test_session(%{username: "test_username"})
        |> assign(:ueberauth_failure, "failed")
        |> get("/auth/keycloak/callback")

      assert redirected_to(conn) == "/"
    end
  end

  @spec auth_for(User.id(), String.t(), String.t() | nil) :: Auth.t()
  defp auth_for(id, email, phone_number, roles \\ ["user"]) do
    %Auth{
      uid: email,
      provider: :keycloak,
      strategy: Ueberauth.Strategy.Oidcc,
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
          id_token: "FAKE ID TOKEN"
        }
      },
      extra: %Extra{
        raw_info: %{
          claims: %{
            "sub" => id
          },
          opts: %{
            module: __MODULE__.FakeOidcc,
            issuer: :keycloak_issuer,
            client_id: "fake_client",
            client_secret: "fake_client_secret"
          },
          userinfo: %{
            "email" => email,
            "email_verified" => true,
            "family_name" => "Rider",
            "given_name" => "John",
            "name" => "John Rider",
            "phone_number" => phone_number,
            "preferred_username" => email,
            "resource_access" => %{
              "t-alerts" => %{
                "roles" => roles
              }
            }
          }
        }
      }
    }
  end

  @spec auth_for_user_with_mbta_uuid(User.id(), String.t(), String.t(), [String.t()], String.t()) ::
          Auth.t()
  defp auth_for_user_with_mbta_uuid(id, email, phone_number, roles, mbta_uuid) do
    %Auth{
      uid: email,
      provider: :keycloak,
      strategy: Ueberauth.Strategy.Oidcc,
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
          id_token: "FAKE ID TOKEN"
        }
      },
      extra: %Extra{
        raw_info: %{
          claims: %{
            "sub" => id
          },
          opts: %{
            module: __MODULE__.FakeOidcc,
            issuer: :keycloak_issuer,
            client_id: "fake_client",
            client_secret: "fake_client_secret"
          },
          userinfo: %{
            "email" => email,
            "email_verified" => true,
            "family_name" => "Rider",
            "given_name" => "John",
            "name" => "John Rider",
            "phone_number" => phone_number,
            "preferred_username" => email,
            "mbta_uuid" => mbta_uuid,
            "resource_access" => %{
              "t-alerts" => %{
                "roles" => roles
              }
            }
          }
        }
      }
    }
  end

  defmodule FakeOidcc do
    def initiate_logout_url("FAKE ID TOKEN", :keycloak_issuer, "fake_client", opts) do
      {:ok, "/end_session?#{URI.encode_query(opts)}"}
    end
  end
end
