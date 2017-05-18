defmodule AlertProcessor.DigestMailer do
  @moduledoc "Digest Mailer interface"
  use Bamboo.Mailer, otp_app: :alert_processor
  import Bamboo.Email
  alias AlertProcessor.Model.Digest

  @doc "digest_email/1 takes a digest and builds a message to a user"
  @spec digest_email(Digest.t) :: Elixir.Bamboo.Email.t
  def digest_email(digest) do
    base_email()
    |> to(digest.user.email)
    |> subject("MBTA Alerts Digest")
    |> html_body(build_message(digest))
    |> text_body(build_message(digest))
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email()
    |> from("faizaan@intrepid.io")
  end

  @spec build_message(Digest.t) :: String.t
  defp build_message(digest) do
    # TODO: Waiting on spec
    digest.serialized_alerts
    |> Enum.join(" ")
  end
end
