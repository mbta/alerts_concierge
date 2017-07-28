defmodule AlertProcessor.DigestMailer do
  @moduledoc "Digest Mailer interface"
  use Bamboo.Mailer, otp_app: :alert_processor
  import Bamboo.Email
  alias AlertProcessor.Model.DigestMessage
  require EEx

  @from Application.get_env(:alert_processor, __MODULE__)[:from]
  @template_dir Application.get_env(:alert_processor, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "digest.html.eex"),
    [:digest_date_groups, :unsubscribe_url])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(~w(#{System.cwd!} lib mail_templates digest.txt.eex)),
    [:digest_date_groups, :unsubscribe_url])

  @doc "digest_email/2 takes a digest and unsubscribe url and builds a message to a user"
  @spec digest_email(DigestMessage.t, String.t) :: Elixir.Bamboo.Email.t
  def digest_email(digest_message, unsubscribe_url) do
    base_email()
    |> to(digest_message.user.email)
    |> subject("MBTA Alerts Digest")
    |> html_body(html_email(digest_message.body, unsubscribe_url))
    |> text_body(text_email(digest_message.body, unsubscribe_url))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    from(new_email(), @from)
  end
end
