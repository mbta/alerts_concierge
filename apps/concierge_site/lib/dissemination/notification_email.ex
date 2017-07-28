defmodule ConciergeSite.Dissemination.NotificationEmail do
  @moduledoc "Bamboo Mailer interface"
  import Bamboo.Email
  alias AlertProcessor.Model.Notification
  alias AlertProcessor.Helpers.ConfigHelper
  require EEx

  @from ConfigHelper.get_string(:send_from_email, :concierge_site)
  @template_dir Application.get_env(:alert_processor, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "notification.html.eex"),
    [:notification])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(~w(#{System.cwd!} .. .. apps alert_processor lib mail_templates notification.txt.eex)),
    [:notification])

  @doc "notification_email/1 takes a notification and builds an email to be sent to user."
  @spec notification_email(Notification.t) :: Elixir.Bamboo.Email.t
  def notification_email(notification) do
    base_email()
    |> to(notification.email)
    |> subject("MBTA Alert")
    |> html_body(html_email(notification))
    |> text_body(text_email(notification))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email(from: @from)
  end
end
