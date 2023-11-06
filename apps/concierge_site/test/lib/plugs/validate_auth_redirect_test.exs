defmodule ConciergeSite.Plugs.ValidateAuthRedirectTest do
  use ConciergeSite.ConnCase
  use Plug.Test

  import Test.Support.Helpers

  alias ConciergeSite.Plugs.ValidateAuthRedirect
  alias Plug.Conn

  describe "ValidateAuthRedirect" do
    @tag :capture_log
    test "sends a bad request response if requesting an invalid auth redirect URI param", %{
      conn: original_conn
    } do
      reassign_env(:concierge_site, :keycloak_base_uri, "https://example.com/TEST-BASE-URI")

      redirect_uri =
        "https://malicious-site.com/TEST-BASE-URI/auth/realms/MBTA/protocol/openid-connect/registrations?client_id=t-alerts&response_type=code&scope=openid"

      original_conn = %Conn{
        original_conn
        | query_params: %{
            "uri" => redirect_uri
          }
      }

      conn = ValidateAuthRedirect.call(original_conn, %{})

      assert response(conn, 400) =~ "Bad redirect URI"
    end

    test "allows the redirect for requests with valid auth redirect URI param", %{
      conn: original_conn
    } do
      reassign_env(:concierge_site, :keycloak_base_uri, "https://example.com/TEST-BASE-URI")

      redirect_uri =
        "https://example.com/TEST-BASE-URI/auth/realms/MBTA/protocol/openid-connect/registrations?client_id=t-alerts&response_type=code&scope=openid"

      original_conn = %Conn{
        original_conn
        | query_params: %{
            "uri" => redirect_uri
          }
      }

      conn = ValidateAuthRedirect.call(original_conn, %{})

      assert conn == original_conn
    end

    test "allows the redirect for requests without a redirect URI param", %{
      conn: original_conn
    } do
      original_conn = %Conn{
        original_conn
        | query_params: %{}
      }

      conn = ValidateAuthRedirect.call(original_conn, %{})

      assert conn == original_conn
    end
  end
end
