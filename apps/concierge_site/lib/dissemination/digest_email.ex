defmodule ConciergeSite.Dissemination.DigestEmail do
  @moduledoc "Digest Mailer interface"
  import Bamboo.Email
  alias AlertProcessor.Model.DigestMessage
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  require EEx

  @from {ConfigHelper.get_string(:send_from_name, :concierge_site),
         ConfigHelper.get_string(:send_from_email, :concierge_site)}
  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "digest.html.eex"),
    [:digest_date_groups, :manage_subscriptions_url, :feedback_url])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates digest.txt.eex)),
    [:digest_date_groups, :manage_subscriptions_url, :feedback_url])

  @doc "digest_email/1 takes a digest and builds a message to a user"
  @spec digest_email(DigestMessage.t) :: Elixir.Bamboo.Email.t
  def digest_email(digest_message) do
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(digest_message.user)
    feedback_url = MailHelper.feedback_url()
    base_email()
    |> to(digest_message.user.email)
    |> subject("MBTA Alerts Digest")
    |> html_body(html_email(digest_message.body, manage_subscriptions_url, feedback_url))
    |> text_body(text_email(digest_message.body, manage_subscriptions_url, feedback_url))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email(from: @from)
  end
end
