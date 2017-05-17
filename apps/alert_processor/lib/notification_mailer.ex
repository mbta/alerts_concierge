defmodule AlertProcessor.NotificationMailer do
  @moduledoc "Bamboo Mailer interface"
  use Bamboo.Mailer, otp_app: :alert_processor
  import Bamboo.Email

  @doc "notification_email/2 takes a message and a user's email address and builds an email to be sent to user."
  @spec notification_email(String.t, String.t) :: Elixir.Bamboo.Email.t
  def notification_email(message, user_email) do
    base_email()
    |> to(user_email)
    |> subject("Test Email")
    |> html_body("<p>" <> message <> "</p>")
    |> text_body(message)
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email()
    |> from("faizaan@intrepid.io")
  end
end
