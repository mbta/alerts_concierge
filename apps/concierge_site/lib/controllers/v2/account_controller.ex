defmodule ConciergeSite.V2.AccountController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.ConfirmationMessage
  alias ConciergeSite.SignInHelper

  def new(conn, _params) do
    account_changeset = User.create_account_changeset(%User{}, %{"sms_toggle" => false})
    render conn, "new.html", account_changeset: account_changeset
  end

  def create(conn, %{"user" => params}) do
    case User.create_account(Map.merge(params, %{"password_confirmation" => params["password"]})) do
      {:ok, user} ->
        ConfirmationMessage.send_confirmation(user)
        SignInHelper.sign_in(conn, user, redirect: :v2_default)
      {:error, changeset} ->
        render conn, "new.html", account_changeset: changeset, errors: errors(changeset)
    end
  end

  defp errors(changeset) do
    Enum.map(changeset.errors, fn({field, _}) ->
      field
    end)
  end

  def options(conn, _params) do
    render conn, "options.html"
  end
end
