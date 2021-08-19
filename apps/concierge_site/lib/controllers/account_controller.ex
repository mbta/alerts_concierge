defmodule ConciergeSite.AccountController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User
  alias AlertProcessor.Repo
  alias ConciergeSite.ConfirmationMessage
  alias ConciergeSite.SignInHelper
  alias ConciergeSite.Mailchimp

  def new(conn, _params, _user, _claims) do
    account_changeset = User.create_account_changeset(%User{}, %{"sms_toggle" => false})
    render(conn, "new.html", account_changeset: account_changeset)
  end

  def edit(conn, _params, user, _claims) do
    conn
    |> message_if_opted_out(user)
    |> render("edit.html", changeset: User.changeset(user), user_id: user.id)
  end

  def edit_password(conn, _params, _user, _claims) do
    render(conn, "edit_password.html")
  end

  def create(conn, %{"user" => params}, _user, _claims) do
    case User.create_account(params) do
      {:ok, user} ->
        ConfirmationMessage.send_email_confirmation(user)
        SignInHelper.sign_in(conn, user)

      {:error, changeset} ->
        render(conn, "new.html", account_changeset: changeset, errors: errors(changeset))
    end
  end

  def update(conn, %{"user" => params}, user, {:ok, claims}) do
    case User.update_account(user, params, Map.get(claims, "imp", user.id)) do
      {:ok, updated_user} ->
        Mailchimp.update_member(updated_user)

        if user.phone_number == nil and updated_user.phone_number != nil do
          ConfirmationMessage.send_sms_confirmation(
            updated_user.phone_number,
            params["sms_toggle"]
          )
        end

        conn
        |> put_flash(:info, "Your account has been updated.")
        |> redirect(to: trip_path(conn, :index))

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          changeset: changeset,
          user_id: user.id,
          errors: errors(changeset)
        )
    end
  end

  def update_password(conn, %{"user" => params}, user, {:ok, claims}) do
    if User.check_password(user, params["current_password"]) do
      case User.update_password(
             user,
             %{"password" => params["password"]},
             Map.get(claims, "imp", user.id)
           ) do
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
    Mailchimp.delete_member(user)
    Repo.delete!(user)
    redirect(conn, to: page_path(conn, :account_deleted))
  end

  def options_new(conn, params, user, _claims) do
    changeset = User.update_account_changeset(user, params)

    render(conn, "options_new.html", changeset: changeset, user: user, sms_toggle: false)
  end

  def options_create(conn, %{"user" => params}, user, {:ok, claims}) do
    case User.update_account(user, params, Map.get(claims, "imp", user.id)) do
      {:ok, updated_user} ->
        Mailchimp.update_member(user)
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
    Enum.map(changeset.errors, fn {field, _} ->
      field
    end)
  end

  defp message_if_opted_out(conn, %User{} = user) do
    if User.inside_opt_out_freeze_window?(user) do
      put_flash(
        conn,
        :error,
        "You opted out of text messages on #{formatted_date(user.sms_opted_out_at)}. You cannot resubscribe for 30 days. If you’d like to continue receiving alerts, you can select to receive notifications by email."
      )
    else
      conn
    end
  end

  defp formatted_date(date) do
    [date.month, date.day, date.year]
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.pad_leading(&1, 2, "0"))
    |> Enum.join("/")
  end

  def mailchimp_update(
        conn,
        %{"type" => "unsubscribe", "data" => %{"email" => email}, "secret" => secret},
        _user,
        _claims
      ) do
    {affected, message} = Mailchimp.handle_unsubscribed(secret, email)
    json(conn, %{status: "ok", message: message, affected: affected})
  end

  def mailchimp_update(
        conn,
        %{
          "type" => "upemail",
          "data" => %{"new_email" => new_email, "old_email" => old_email},
          "secret" => secret
        },
        _user,
        _claims
      ) do
    {affected, message} = Mailchimp.handle_email_changed(secret, old_email, new_email)
    json(conn, %{status: "ok", message: message, affected: affected})
  end

  def mailchimp_update(conn, _params, _user, _claims) do
    json(conn, %{status: "ok", message: "invalid request"})
  end
end
