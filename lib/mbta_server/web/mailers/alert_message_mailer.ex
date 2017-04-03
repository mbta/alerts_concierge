defmodule MbtaServer.AlertMessageMailer do
  @moduledoc "Module to handle sending email messages through Bamboo's smtp adapter."
  use Bamboo.Phoenix, view: MbtaServer.Email.AlertMessageView

  @doc "alert_message_email/2 takes a message and a user's email address and builds an email to be sent to user."
  @spec alert_message_email(String.t, String.t) :: Elixir.Bamboo.Email.t
  def alert_message_email(message, user_email) do
    base_email()
    |> to(user_email)
    |> subject("Test Email")
    |> assign(:subject, "Test Email")
    |> assign(:email_body, message)
    |> render(:alert)
  end

  @spec base_email() :: Elixir.Bamboo.Email.t
  defp base_email do
    new_email()
    |> from("faizaan@intrepid.io")
    |> put_layout({MbtaServer.Web.LayoutView, :mail})
  end
end
