defmodule AlertProcessor.NotificationMailer do
  @moduledoc "Bamboo Mailer interface"
  use Bamboo.Mailer, otp_app: :alert_processor
  import Bamboo.Email
  alias AlertProcessor.Model.Notification
  require EEx

  @from Application.get_env(:alert_processor, __MODULE__)[:from]
  @template_dir Application.get_env(:alert_processor, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "notification.html.eex"),
    [:notification, :unsubscribe_url])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates notification.txt.eex)),
    [:notification, :unsubscribe_url])

  @doc "notification_email/2 takes a message and an unsubscribe url and builds an email to be sent to user."
  @spec notification_email(Notification.t, String.t) :: Elixir.Bamboo.Email.t
  def notification_email(notification, unsubscribe_url) do
    base_email()
    |> to(notification.email)
    |> subject("MBTA Alert")
    |> html_body(html_email(notification, unsubscribe_url))
    |> text_body(text_email(notification, unsubscribe_url))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email()
    |> from(@from)
  end
end
