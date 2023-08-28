defmodule ConciergeSite.Dissemination.Email do
  @moduledoc false
  use Bamboo.Phoenix, view: ConciergeSite.EmailView
  alias AlertProcessor.Helpers.ConfigHelper
  alias ConciergeSite.Helpers.MailHelper
  alias ConciergeSite.MJML

  require ConciergeSite.MJML
  require EEx

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
