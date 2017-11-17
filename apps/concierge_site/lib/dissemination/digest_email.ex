defmodule ConciergeSite.Dissemination.DigestEmail do
  @moduledoc "Digest Mailer interface"
  import Bamboo.Email
  alias AlertProcessor.Model.DigestMessage
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  require EEx

  @from ConfigHelper.get_string(:send_from_email, :concierge_site)
  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "digest.html.eex"),
    [:digest_date_groups, :unsubscribe_url, :manage_subscriptions_url])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates digest.txt.eex)),
    [:digest_date_groups, :unsubscribe_url])

  @doc "digest_email/1 takes a digest and builds a message to a user"
  @spec digest_email(DigestMessage.t) :: Elixir.Bamboo.Email.t
  def digest_email(digest_message) do
    unsubscribe_url = MailHelper.unsubscribe_url(digest_message.user)
    manage_subscriptions_url = MailHelper.manage_subscriptions_url(digest_message.user)
    base_email()
    |> to(digest_message.user.email)
    |> subject("MBTA Alerts Digest")
    |> html_body(html_email(digest_message.body, unsubscribe_url, manage_subscriptions_url))
    |> text_body(text_email(digest_message.body, unsubscribe_url))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email(from: @from)
  end
end
