defmodule ConciergeSite.UnsubscribeController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User

  def unsubscribe(conn, params, _user, _claims) do
    with {:ok, claims} <- Guardian.decode_and_verify(params["token"]),
      default_permissions <- Guardian.Permissions.from_claims(claims, :default),
      true <- Guardian.Permissions.any?(default_permissions, [:unsubscribe], :default),
      {:ok, user} <- Guardian.serializer.from_token(claims["sub"]),
      :ok <- User.clear_holding_queue_for_user_id(user.id),
      {1, nil} <- User.put_users_on_indefinite_vacation([user.id]) do
      render(conn, "unsubscribe.html")
    else
      _ ->
        conn
        |> put_flash(:error, "Invalid token")
        |> redirect(to: "/")
    end
  end
end
