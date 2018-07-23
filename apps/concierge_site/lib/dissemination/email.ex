defmodule ConciergeSite.Dissemination.Email do
  @moduledoc false
  use Bamboo.Phoenix, view: ConciergeSite.EmailView
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  require EEx

  @from {ConfigHelper.get_string(:send_from_name, :concierge_site),
         ConfigHelper.get_string(:send_from_email, :concierge_site)}
  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :password_reset_html_email,
    Path.join(@template_dir, "password_reset.html.eex"),
    [:reset_token])
  EEx.function_from_file(
    :def,
    :password_reset_text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates password_reset.txt.eex)),
    [:reset_token])

  def password_reset_email(user, reset_token) do
    base_email()
    |> to(user.email)
    |> subject("Reset your T-Alerts password")
    |> html_body(password_reset_html_email(reset_token))
    |> text_body(password_reset_text_email(reset_token))
  end

  EEx.function_from_file(
    :def,
    :confirmation_html_email,
    Path.join(@template_dir, "confirmation.html.eex"),
    [:manage_subscriptions_url, :feedback_url])
  EEx.function_from_file(
    :def,
    :confirmation_text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates confirmation.txt.eex)),
    [:manage_subscriptions_url, :feedback_url])

  def confirmation_email(user) do
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(user)
    feedback_url = MailHelper.feedback_url()
    base_email()
    |> to(user.email)
    |> subject("Welcome to T-Alerts")
    |> html_body(confirmation_html_email(manage_subscriptions_url, feedback_url))
    |> text_body(confirmation_text_email(manage_subscriptions_url, feedback_url))
  end

  EEx.function_from_file(
    :def,
    :targeted_notification_html_email,
    Path.join(@template_dir, "targeted_notification.html.eex"),
    [:subject, :body, :manage_subscriptions_url, :feedback_url])
  EEx.function_from_file(
    :def,
    :targeted_notification_text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates targeted_notification.txt.eex)),
    [:subject, :body, :manage_subscriptions_url, :feedback_url])

  def targeted_notification_email(user, subject, body) do
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(user)
    feedback_url = MailHelper.feedback_url()

    base_email()
    |> to(user.email)
    |> subject(subject)
    |> html_body(targeted_notification_html_email(subject, body, manage_subscriptions_url, feedback_url))
    |> text_body(targeted_notification_text_email(subject, body, manage_subscriptions_url, feedback_url))
  end

  defp base_email do
    new_email(from: @from)
  end
end
