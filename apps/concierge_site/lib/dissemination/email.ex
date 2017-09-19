defmodule ConciergeSite.Dissemination.Email do
  @moduledoc false
  use Bamboo.Phoenix, view: ConciergeSite.EmailView
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  require EEx

  @from ConfigHelper.get_string(:send_from_email, :concierge_site)
  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :password_reset_html_email,
    Path.join(@template_dir, "password_reset.html.eex"),
    [:password_reset_id, :unsubscribe_url, :manage_subscriptions_url])
  EEx.function_from_file(
    :def,
    :password_reset_text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates password_reset.txt.eex)),
    [:password_reset_id, :unsubscribe_url])

  def password_reset_email(user, password_reset) do
    unsubscribe_url = MailHelper.unsubscribe_url(user)
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(user)
    base_email()
    |> to(user.email)
    |> subject("Reset Your MBTA Alerts Password")
    |> html_body(password_reset_html_email(password_reset.id, unsubscribe_url, manage_subscriptions_url))
    |> text_body(password_reset_text_email(password_reset.id, unsubscribe_url))
  end

  EEx.function_from_file(
    :def,
    :unknown_password_reset_html_email,
    Path.join(@template_dir, "unknown_password_reset.html.eex"),
    [:email])
  EEx.function_from_file(
    :def,
    :unknown_password_reset_text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates unknown_password_reset.txt.eex)),
    [:email])

  def unknown_password_reset_email(email) do
    base_email()
    |> to(email)
    |> subject("MBTA Alerts Password Reset Attempted")
    |> html_body(unknown_password_reset_html_email(email))
    |> text_body(unknown_password_reset_text_email(email))
  end

  EEx.function_from_file(
    :def,
    :confirmation_html_email,
    Path.join(@template_dir, "confirmation.html.eex"),
    [:unsubscribe_url, :disable_account_url, :manage_subscriptions_url])
  EEx.function_from_file(
    :def,
    :confirmation_text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates confirmation.txt.eex)),
    [:unsubscribe_url, :disable_account_url])

  def confirmation_email(user) do
    unsubscribe_url = MailHelper.unsubscribe_url(user)
    disable_account_url = MailHelper.disable_account_url(user)
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(user)
    base_email()
    |> to(user.email)
    |> subject("MBTA Alerts Account Confirmation")
    |> html_body(confirmation_html_email(unsubscribe_url, disable_account_url, manage_subscriptions_url))
    |> text_body(confirmation_text_email(unsubscribe_url, disable_account_url))
  end

  EEx.function_from_file(
    :def,
    :targeted_notification_html_email,
    Path.join(@template_dir, "targeted_notification.html.eex"),
    [:subject, :body, :manage_subscriptions_url])
  EEx.function_from_file(
    :def,
    :targeted_notification_text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates targeted_notification.txt.eex)),
    [:body])

  def targeted_notification_email(user, subject, body) do
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(user)

    base_email()
    |> to(user.email)
    |> subject(subject)
    |> html_body(targeted_notification_html_email(subject, body, manage_subscriptions_url))
    |> text_body(targeted_notification_text_email(body))
  end

  defp base_email do
    new_email(from: @from)
  end
end
