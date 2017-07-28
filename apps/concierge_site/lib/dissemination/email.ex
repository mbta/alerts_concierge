defmodule ConciergeSite.Dissemination.Email do
  use Bamboo.Phoenix, view: ConciergeSite.EmailView
  alias AlertProcessor.Helpers.ConfigHelper

  @from ConfigHelper.get_string(:send_from_email, :concierge_site)

  def password_reset_text_email({email, password_reset_id}) do
    base_email()
    |> to(email)
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
    base_email()
    |> to(email)
    |> subject("MBTA Alerts Password Reset Attempted")
    |> render("unknown_password_reset.text", email: email)
  end

  def unknown_password_reset_html_email(email) do
    email
    |> unknown_password_reset_text_email()
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render("unknown_password_reset.html", email: email)
  end

  def confirmation_email(email) do
    base_email()
    |> to(email)
    |> subject("MBTA Alerts Account Confirmation")
    |> put_html_layout({ConciergeSite.LayoutView, "email.html"})
    |> render(:confirmation)
  end

  defp base_email do
    new_email(from: @from)
  end
end
