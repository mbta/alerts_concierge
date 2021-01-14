defmodule ConciergeSite.Dissemination.Email do
  @moduledoc false
  use Bamboo.Phoenix, view: ConciergeSite.EmailView
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  require EEx

  @template_dir Application.fetch_env!(:concierge_site, :mail_template_dir)

  EEx.function_from_file(
    :def,
    :password_reset_html_email,
    Path.join(@template_dir, "password_reset.html.eex"),
    [:reset_token]
  )

  EEx.function_from_file(
    :def,
    :password_reset_text_email,
    Path.join(~w(#{System.cwd!()} lib mail_templates password_reset.txt.eex)),
    [:reset_token]
  )

  def password_reset_email(user, reset_token) do
    base_email()
    |> to(user.email)
    |> subject("Reset your T-Alerts password")
    |> html_body(password_reset_html_email(reset_token))
    |> text_body(password_reset_text_email(reset_token))
  end

  EEx.function_from_file(
    :def,
    :confirmation_html_email,
    Path.join(@template_dir, "confirmation.html.eex"),
    [:manage_subscriptions_url, :support_url]
  )

  EEx.function_from_file(
    :def,
    :confirmation_text_email,
    Path.join(~w(#{System.cwd!()} lib mail_templates confirmation.txt.eex)),
    [:manage_subscriptions_url, :support_url]
  )

  def confirmation_email(user) do
    manage_subscriptions_url = MailHelper.manage_subscriptions_url()
    support_url = MailHelper.support_url()

    base_email()
    |> to(user.email)
    |> subject("Welcome to T-Alerts")
    |> html_body(confirmation_html_email(manage_subscriptions_url, support_url))
    |> text_body(confirmation_text_email(manage_subscriptions_url, support_url))
  end

  @spec base_email() :: Bamboo.Email.t()
  def base_email do
    new_email(
      from:
        {ConfigHelper.get_string(:send_from_name, :concierge_site),
         ConfigHelper.get_string(:send_from_email, :concierge_site)}
    )
  end
end
