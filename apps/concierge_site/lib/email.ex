defmodule ConciergeSite.Email do
  use Bamboo.Phoenix, view: ConciergeSite.EmailView

  @from Application.get_env(:concierge_site, __MODULE__)[:from]

  def password_reset_text_email({email, password_reset_id}) do
    new_email()
    |> to(email)
    |> from(@from)
    |> subject("Reset Your MBTA Alerts Password")
    |> render("password_reset.text", password_reset_id: password_reset_id)
  end

  def password_reset_html_email(email, password_reset_id) do
    {email, password_reset_id}
    |> password_reset_text_email()
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render("password_reset.html", password_reset_id: password_reset_id)
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
    |> render("unknown_password_reset.html", email: email)
  end

  def confirmation_email(email) do
    new_email()
    |> to(email)
    |> from(@from)
    |> subject("MBTA Alerts Account Confirmation")
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render(:confirmation)
  end
end
