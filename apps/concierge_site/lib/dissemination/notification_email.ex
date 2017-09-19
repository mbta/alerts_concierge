defmodule ConciergeSite.Dissemination.NotificationEmail do
  @moduledoc "Bamboo Mailer interface"
  import Bamboo.Email
  import AlertProcessor.Helpers.StringHelper, only: [capitalize_first: 1]
  alias AlertProcessor.Model.{Alert, Notification}
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  require EEx

  @from ConfigHelper.get_string(:send_from_email, :concierge_site)
  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "notification.html.eex"),
    [:notification, :unsubscribe_url, :manage_subscriptions_url])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates notification.txt.eex)),
    [:notification, :unsubscribe_url])

  @doc "notification_email/1 takes a notification and builds an email to be sent to user."
  @spec notification_email(Notification.t) :: Elixir.Bamboo.Email.t
  def notification_email(%Notification{user: user} = notification) do
    unsubscribe_url = MailHelper.unsubscribe_url(user)
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(user)
    notification_email_subject = email_subject(notification)

    base_email()
    |> to(user.email)
    |> subject(notification_email_subject)
    |> html_body(html_email(notification, unsubscribe_url, manage_subscriptions_url))
    |> text_body(text_email(notification, unsubscribe_url))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email(from: @from)
  end

  def email_subject(notification) do
    alert = notification.alert
    IO.iodata_to_binary([email_prefix(alert), notification.service_effect, email_suffix(alert)])
  end

  defp email_prefix(%Alert{timeframe: nil}),
    do: ""
  defp email_prefix(%Alert{timeframe: timeframe}),
    do: [capitalize_first(timeframe), ": "]

  defp email_suffix(%Alert{recurrence: nil}), do: ""
  defp email_suffix(%Alert{recurrence: recurrence}), do: [" ", recurrence]
end
