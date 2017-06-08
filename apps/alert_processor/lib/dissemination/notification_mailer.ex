defmodule AlertProcessor.NotificationMailer do
  @moduledoc "Bamboo Mailer interface"
  use Bamboo.Mailer, otp_app: :alert_processor
  import Bamboo.Email
  alias AlertProcessor.Model.Notification
  require EEx

  @from Application.get_env(:alert_processor, __MODULE__)[:from]
  @template_dir Path.join(~w(#{File.cwd!} lib mail_templates))

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "notification.html.eex"),
    [:notification, :notification_styles])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(@template_dir, "notification.txt.eex"),
    [:notification])
  EEx.function_from_file(
    :def,
    :notification_styles,
    Path.join(@template_dir, "notification_styles.css"),
    []
  )

  @doc "notification_email/2 takes a message and a user's email address and builds an email to be sent to user."
  @spec notification_email(Notification.t, String.t) :: Elixir.Bamboo.Email.t
  def notification_email(notification, user_email) do
    base_email()
    |> to(user_email)
    |> subject("MBTA Alert")
    |> html_body(html_email(notification, notification_styles()))
    |> text_body(text_email(notification))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email()
    |> from(@from)
  end
end
