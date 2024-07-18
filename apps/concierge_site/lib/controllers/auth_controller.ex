defmodule ConciergeSite.AuthController do
  use ConciergeSite.Web, :controller

  require Logger

  alias AlertProcessor.Helpers.PhoneNumber
  alias AlertProcessor.Model.User
  alias AlertProcessor.Repo
  alias ConciergeSite.SessionHelper
  alias Plug.Conn

  plug(Ueberauth)

  @spec callback(Conn.t(), any) :: Conn.t()
  def callback(
        %{
          assigns: %{
            ueberauth_auth:
              %{
                info: %{email: email, phone: phone_number},
                extra: %{
                  raw_info: %{
                    claims: %{"sub" => id},
                    userinfo: userinfo
                  }
                }
              } = auth
          }
        } = conn,
        _params
      ) do
    phone_number = PhoneNumber.strip_us_country_code(phone_number)

    role = parse_role({:ok, userinfo})
    mbta_uuid = Map.get(userinfo, "mbta_uuid")

    user =
      %{id: id, mbta_uuid: mbta_uuid}
      |> get_or_create_user(email, phone_number, role)

    logout_params = %{
      post_logout_redirect_uri: page_url(conn, :landing)
    }

    {:ok, logout_uri} = UeberauthOidcc.initiate_logout_url(auth, logout_params)

    case user do
      nil ->
        SessionHelper.sign_out(conn, skip_oidc_sign_out: true)

      _ ->
        user = use_props_from_token(user, email, phone_number, role)

        conn
        |> put_session("logout_uri", logout_uri)
        |> SessionHelper.sign_in(user)
    end
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    Logger.info("Ueberauth failure: #{inspect(failure)}")
    SessionHelper.sign_out(conn, skip_oidc_sign_out: true)
  end

  def callback(%{assigns: assigns} = conn, params) do
    Logger.warn(
      "Unexpected Ueberauth callback assigns=#{inspect(assigns)} params=#{inspect(params)}"
    )

    SessionHelper.sign_out(conn, skip_oidc_sign_out: true)
  end

  @spec logout(Conn.t(), map()) :: Conn.t()
  def logout(conn, _params) do
    SessionHelper.sign_out(conn)
  end

  @spec get_or_create_user(
          %{id: User.id(), mbta_uuid: User.id() | nil},
          String.t(),
          String.t() | nil,
          String.t()
        ) ::
          User.t() | nil
  defp get_or_create_user(%{id: id, mbta_uuid: mbta_uuid} = id_map, email, phone_number, role) do
    # This checks both the normal id from Keycloak, and the legacy mbta_uuid. We should get either 0 or 1 users back.
    user_list = User.get_by_alternate_id(id_map)

    case length(user_list) do
      0 ->
        # If neither ID is found, the user just created their account in Keycloak so we need to add them to our database
        Repo.insert!(%User{
          id: id,
          email: email,
          phone_number: phone_number,
          role: role
        })

        User.get(id)

      1 ->
        # If 1 user is found, we want to return that user
        hd(user_list)

      2 ->
        # If 2 users are found, something weird happened. Log and return nil. User will be redirected to landing page.
        Logger.warn("User with 2 ids found. sub id: #{id}, mbta_uuid: #{mbta_uuid}")
        nil
    end
  end

  # Display the email and phone number we received in the token rather than the
  # values from the database. We will eventually receive an SQS message from
  # Keycloak and update these values in our local database (so that we able
  # able to use them to send notifications), but in cases where the user just
  # changed one of these fields in Keycloak, we might not have had time receive
  # that message yet, so the values in the token are more authoritative.
  @spec use_props_from_token(
          User.t(),
          String.t(),
          String.t() | nil,
          String.t()
        ) ::
          User.t() | nil
  defp use_props_from_token(user, email, phone_number, role) do
    %User{
      user
      | email: email,
        phone_number: phone_number,
        role: role
    }
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
end
