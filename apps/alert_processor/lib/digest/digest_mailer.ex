defmodule AlertProcessor.DigestMailer do
  @moduledoc "Digest Mailer interface"
  use Bamboo.Mailer, otp_app: :alert_processor
  import Bamboo.Email
  alias AlertProcessor.Model.DigestMessage
  require EEx

  @from Application.get_env(:alert_processor, __MODULE__)[:from]
  @template_dir Path.join(~w(#{File.cwd!} lib mail_templates))

  EEx.function_from_file(
    :def,
    :html_email,
    Path.join(@template_dir, "digest_layout.html.eex"),
    [:digest_date_groups])
  EEx.function_from_file(
    :def,
    :text_email,
    Path.join(@template_dir, "digest_layout.txt.eex"),
    [:digest_date_groups])

  @doc "digest_email/1 takes a digest and builds a message to a user"
  @spec digest_email(DigestMessage.t) :: Elixir.Bamboo.Email.t
  def digest_email(digest_message) do
    base_email()
    |> to(digest_message.user.email)
    |> subject("MBTA Alerts Digest")
    |> html_body(html_email(digest_message.body))
    |> text_body(text_email(digest_message.body))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    from(new_email(), @from)
  end
end
