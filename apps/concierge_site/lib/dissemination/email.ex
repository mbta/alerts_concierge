defmodule ConciergeSite.Dissemination.Email do
  use Bamboo.Phoenix, view: ConciergeSite.EmailView
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper

  @from ConfigHelper.get_string(:send_from_email, :concierge_site)

  def password_reset_email(user, password_reset) do
    unsubscribe_url = MailHelper.unsubscribe_url(user)
    base_email()
    |> to(user.email)
    |> subject("Reset Your MBTA Alerts Password")
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render(:password_reset, password_reset_id: password_reset.id, unsubscribe_url: unsubscribe_url)
  end

  def unknown_password_reset_email(email) do
    base_email()
    |> to(email)
    |> subject("MBTA Alerts Password Reset Attempted")
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render(:unknown_password_reset, email: email)
  end

  def confirmation_email(user) do
    unsubscribe_url = MailHelper.unsubscribe_url(user)
    base_email()
    |> to(user.email)
    |> subject("MBTA Alerts Account Confirmation")
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render(:confirmation, unsubscribe_url: unsubscribe_url)
  end

  defp base_email do
    new_email(from: @from)
  end
end
