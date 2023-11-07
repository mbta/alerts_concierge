defmodule ConciergeSite.AccountController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.Model.User
  alias AlertProcessor.Repo
  alias ConciergeSite.ConfirmationMessage
  alias ConciergeSite.Mailchimp

  require Logger

  def new(conn, _params) do
    redirect(conn, to: "/auth/register")
  end

  def edit(%{assigns: %{current_user: user}} = conn, _params) do
    conn
    |> put_flash(:warning, communication_mode_flash(user))
    |> render("edit.html", changeset: User.changeset(user), user_id: user.id)
  end

  def edit_password(conn, _params) do
    redirect(conn, external: ConciergeSite.AccountView.edit_password_url(conn))
  end

  def update(%{assigns: %{current_user: user}} = conn, %{"user" => params}) do
    case User.update_account(user, params, user) do
      {:ok, updated_user} ->
        Mailchimp.update_member(updated_user)

        if user.communication_mode != "sms" and updated_user.communication_mode == "sms" do
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

  def delete(%{assigns: %{current_user: user}} = conn, _params) do
    Mailchimp.delete_member(user)
    Repo.delete!(user)
    redirect(conn, to: page_path(conn, :account_deleted))
  end

  def options_new(%{assigns: %{current_user: user}} = conn, params) do
    changeset = User.update_account_changeset(user, params)

    render(conn, "options_new.html", changeset: changeset, user: user, sms_toggle: false)
  end

  def options_create(%{assigns: %{current_user: user}} = conn, %{"user" => params}) do
    case User.update_account(user, params, user) do
      {:ok, updated_user} ->
        Mailchimp.update_member(user)

        if updated_user.communication_mode == "sms" do
          ConfirmationMessage.send_sms_confirmation(
            updated_user.phone_number,
            params["sms_toggle"]
          )
        else
          ConfirmationMessage.send_email_confirmation(updated_user)
        end

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

  defp communication_mode_flash(%User{sms_opted_out_at: sms_opted_out_at} = user)
       when not is_nil(sms_opted_out_at) do
    communication_mode_flash_for_sms_opt_out(user, User.inside_opt_out_freeze_window?(user))
  end

  defp communication_mode_flash(%User{
         email: email,
         communication_mode: "none",
         email_rejection_status: "bounce"
       }) do
    "Alerts are disabled for your account: We encountered an error trying to deliver email alerts
    to \"#{email}\". To resume alerts, ensure your address is entered correctly and is able to
    receive email, then select email delivery below. Or select text message delivery instead."
  end

  defp communication_mode_flash(%User{
         communication_mode: "none",
         email_rejection_status: "complaint"
       }) do
    "Alerts are disabled for your account: We received a spam report or other complaint from your
    email provider. To resume alerts, ensure your address is entered correctly and select email
    delivery below. Or select text message delivery instead."
  end

  defp communication_mode_flash(%User{communication_mode: "none"}) do
    "Alerts are disabled for your account. To resume alerts, select email or text message delivery
    below."
  end

  defp communication_mode_flash(_user), do: nil

  defp communication_mode_flash_for_sms_opt_out(
         %User{communication_mode: "email", sms_opted_out_at: sms_opted_out_at},
         true
       ) do
    "Text message delivery is disabled: You opted out of text message alerts on
    #{formatted_date(sms_opted_out_at)}. Due to carrier anti-spam rules, we can’t send you any
    further text messages until 30 days after this date."
  end

  defp communication_mode_flash_for_sms_opt_out(
         %User{communication_mode: "none", sms_opted_out_at: sms_opted_out_at},
         true
       ) do
    "Alerts are disabled for your account: You opted out of text message alerts on
    #{formatted_date(sms_opted_out_at)}. Due to carrier anti-spam rules, we can’t send you any
    further text messages until 30 days after this date. If you’d like to receive alerts during
    this time, select email delivery below."
  end

  defp communication_mode_flash_for_sms_opt_out(
         %User{communication_mode: "none", sms_opted_out_at: sms_opted_out_at},
         false
       ) do
    "Alerts are disabled for your account: You opted out of text message alerts on
    #{formatted_date(sms_opted_out_at)}. To resume alerts, select email or text message delivery
    below."
  end

  defp communication_mode_flash_for_sms_opt_out(_, _), do: nil

  defp formatted_date(date) do
    [date.month, date.day, date.year]
    |> Enum.map(&to_string/1)
    |> Enum.map_join("/", &String.pad_leading(&1, 2, "0"))
  end

  def mailchimp_update(conn, %{
        "type" => "unsubscribe",
        "data" => %{"email" => email},
        "secret" => secret
      }) do
    {affected, message} = Mailchimp.handle_unsubscribed(secret, email)
    json(conn, %{status: "ok", message: message, affected: affected})
  end

  def mailchimp_update(
        conn,
        %{
          "type" => "upemail",
          "data" => %{"new_email" => new_email, "old_email" => old_email},
          "secret" => secret
        }
      ) do
    {affected, message} = Mailchimp.handle_email_changed(secret, old_email, new_email)
    json(conn, %{status: "ok", message: message, affected: affected})
  end

  def mailchimp_update(conn, _params) do
    json(conn, %{status: "ok", message: "invalid request"})
  end
end
