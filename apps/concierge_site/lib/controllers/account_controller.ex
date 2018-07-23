defmodule ConciergeSite.AccountController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.ConfirmationMessage
  alias ConciergeSite.SignInHelper

  def new(conn, _params, _user, _claims) do
    account_changeset = User.create_account_changeset(%User{}, %{"sms_toggle" => false})
    render conn, "new.html", account_changeset: account_changeset
  end

  def edit(conn, _params, user, _claims) do
    render conn, "edit.html", changeset: User.changeset(user), user_id: user.id
  end

  def edit_password(conn, _params, _user, _claims) do
    render conn, "edit_password.html"
  end

  def create(conn, %{"user" => params}, _user, _claims) do
    case User.create_account(params) do
      {:ok, user} ->
        ConfirmationMessage.send_email_confirmation(user)
        SignInHelper.sign_in(conn, user, redirect: :default)
      {:error, changeset} ->
        render conn, "new.html", account_changeset: changeset, errors: errors(changeset)
    end
  end

  def update(conn, %{"user" => params}, user, {:ok, claims}) do
    case User.update_account(user, params, Map.get(claims, "imp", user.id)) do
      {:ok, updated_user} ->
        if user.phone_number == nil and updated_user.phone_number != nil do
          ConfirmationMessage.send_sms_confirmation(updated_user.phone_number, params["sms_toggle"])
        end
        conn
        |> put_flash(:info, "Your account has been updated.")
        |> redirect(to: trip_path(conn, :index))
      {:error, changeset} -> render conn, "edit.html", changeset: changeset,
                                                       user_id: user.id,
                                                       errors: errors(changeset)
    end
  end

  def update_password(conn, %{"user" => params}, user, {:ok, claims}) do
    if User.check_password(user, params["current_password"]) do
      case User.update_password(user, %{"password" => params["password"]}, Map.get(claims, "imp", user.id)) do
        {:ok, _} -> 
          conn
          |> put_flash(:info, "Your password has been updated.")
          |> redirect(to: trip_path(conn, :index))
        {:error, _} ->
          conn
          |> put_flash(:error, "New password format is incorrect. Please try again.")
          |> render("edit_password.html")
      end
    else 
      conn
      |> put_flash(:error, "Current password is incorrect. Please try again.")
      |> render("edit_password.html")
    end
  end

  def delete(conn, _params, user, _claims) do
    User.delete(user)
    redirect(conn, to: page_path(conn, :account_deleted))
  end

  def options_new(conn, _params, user, _claims) do
    changeset = User.update_account_changeset(user)

    render conn, "options_new.html", changeset: changeset, user: user, sms_toggle: false
  end

  def options_create(conn, %{"user" => params}, user, {:ok, claims}) do
    case User.update_account(user, params, Map.get(claims, "imp", user.id)) do
      {:ok, updated_user} ->
        ConfirmationMessage.send_sms_confirmation(updated_user.phone_number, params["sms_toggle"])
        conn
        |> redirect(to: trip_path(conn, :new))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Preferences could not be saved. Please see errors below.")
        |> render("options_new.html", user: user, changeset: changeset)
    end
  end

  defp errors(changeset) do
    Enum.map(changeset.errors, fn({field, _}) ->
      field
    end)
  end
end
