defmodule ConciergeSite.AccountController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.Model.User
  alias ConciergeSite.ConfirmationMessage

  plug :scrub_params, "user" when action in [:create]

  def new(conn, _params) do
    account_changeset = User.create_account_changeset(%User{}, %{"sms_toggle" => false})
    render conn, "new.html", account_changeset: account_changeset, errors: []
  end

  def create(conn, %{"user" => user_params}) do
    case User.create_account(user_params) do
      {:ok, user} ->
        ConfirmationMessage.send_confirmation(user)
        conn
        |> Guardian.Plug.sign_in(user, :access, perms: %{default: Guardian.Permissions.max})
        |> redirect(to: "/my-subscriptions")
      {:error, changeset} ->
        render conn, "new.html", account_changeset: changeset, errors: errors(changeset)
    end
  end

  defp errors(changeset) do
    Enum.map(changeset.errors, fn({field, _}) ->
      field
    end)
  end
end
