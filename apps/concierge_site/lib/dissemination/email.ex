defmodule ConciergeSite.Dissemination.Email do
  @moduledoc false
  use Bamboo.Phoenix, view: ConciergeSite.EmailView
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  alias ConciergeSite.MJML

  require ConciergeSite.MJML
  require EEx

  @thirty_days_in_seconds 2_592_000

  MJML.function_from_template(
    :def,
    :confirmation_html_email,
    "confirmation.mjml",
    [:manage_subscriptions_url, :support_url]
  )

  EEx.function_from_file(
    :def,
    :confirmation_text_email,
    Path.join(~w(#{File.cwd!()} lib mail_templates confirmation.txt.eex)),
    [:manage_subscriptions_url, :support_url]
  )

  def confirmation_email(user) do
    manage_subscriptions_url = MailHelper.manage_subscriptions_url()
    support_url = MailHelper.support_url()

    base_email()
    |> add_unsubscribe_header(user.id)
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

  def add_unsubscribe_header(email, user_id) do
    secret_key_base =
      Application.fetch_env!(:concierge_site, ConciergeSite.Endpoint)
      |> Keyword.fetch!(:secret_key_base)

    encrypted_user_id =
      Plug.Crypto.encrypt(secret_key_base, secret_key_base, user_id,
        max_age: @thirty_days_in_seconds
      )

    host_url = Application.get_env(:concierge_site, :host_url)

    email
    |> put_header("List-Unsubscribe-Post", "List-Unsubscribe=One-Click")
    |> put_header(
      "List-Unsubscribe",
      "<https://#{host_url}/unsubscribe/#{encrypted_user_id}>"
    )
  end
end
