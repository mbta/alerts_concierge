defmodule MbtaServer.Web.SessionController do
  @moduledoc """
  Handles creating and destroying of a session (login/logout)
  """
  use MbtaServer.Web, :controller
  alias MbtaServer.User
  plug :scrub_params, "user" when action in [:create]

  def new(conn, _params) do
    changeset = User.login_changeset(%User{})
    render conn, "new.html", login_changeset: changeset
  end

  def create(conn, %{"user" => login_params}) do
    case User.authenticate(login_params) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: "/my-subscriptions")
      {:error, changeset} ->
        render conn, "new.html", login_changeset: changeset
    end
  end
end
