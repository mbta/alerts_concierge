defmodule AlertProcessor.DigestMailer do
  @moduledoc "Digest Mailer interface"
  use Bamboo.Mailer, otp_app: :alert_processor
  import Bamboo.Email
  alias AlertProcessor.Model.DigestMessage

  @from Application.get_env(:alert_processor, __MODULE__)[:from]

  @doc "digest_email/1 takes a digest and builds a message to a user"
  @spec digest_email(DigestMessage.t) :: Elixir.Bamboo.Email.t
  def digest_email(digest_message) do
    base_email()
    |> to(digest_message.user.email)
    |> subject("MBTA Alerts Digest")
    |> html_body(digest_message.body)
    |> text_body(digest_message.body)
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    from(new_email(), @from)
  end
end
