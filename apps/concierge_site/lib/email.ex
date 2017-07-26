defmodule ConciergeSite.Email do
  use Bamboo.Phoenix, view: ConciergeSite.EmailView
  alias AlertProcessor.MailHelper
  @from Application.get_env(:concierge_site, __MODULE__)[:from]

  def password_reset_text_email({email, password_reset_id, unsubscribe_url}) do
    new_email()
    |> to(email)
    |> from(@from)
    |> subject("Reset Your MBTA Alerts Password")
    |> render("password_reset.text", password_reset_id: password_reset_id, unsubscribe_url: unsubscribe_url)
  end

  def password_reset_html_email(email, password_reset_id, unsubscribe_url) do
    {email, password_reset_id, unsubscribe_url}
    |> password_reset_text_email()
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render("password_reset.html", password_reset_id: password_reset_id, unsubscribe_url: unsubscribe_url)
  end

  def unknown_password_reset_text_email(email) do
    new_email()
    |> to(email)
    |> from(@from)
    |> subject("MBTA Alerts Password Reset Attempted")
    |> render("unknown_password_reset.text", email: email)
  end

  def unknown_password_reset_html_email(email) do
    email
    |> unknown_password_reset_text_email()
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render("unknown_password_reset.html", email: email)
  end

  def confirmation_email(user) do
    unsubscribe_url = MailHelper.unsubscribe_url(user)
    new_email()
    |> to(user.email)
    |> from(@from)
    |> subject("MBTA Alerts Account Confirmation")
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render(:confirmation, unsubscribe_url: unsubscribe_url)
  end
end
