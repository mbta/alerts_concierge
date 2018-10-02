defmodule ConciergeSite.Helpers.MailHelper do
  @moduledoc """
  Functions to use in rendering dynamically generated properties on
  digest emails
  """

  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  alias ConciergeSite.Router.Helpers
  alias AlertProcessor.Helpers.ConfigHelper
  require EEx

  EEx.function_from_file(:def, :html_footer, Path.join(@template_dir, "_footer.html.eex"), [
    :manage_subscriptions_url,
    :feedback_url
  ])

  EEx.function_from_file(:def, :text_footer, Path.join(@template_dir, "_footer.txt.eex"), [
    :manage_subscriptions_url,
    :feedback_url
  ])

  EEx.function_from_file(:def, :html_header, Path.join(@template_dir, "_header.html.eex"), [])

  @doc """
  Return the MBTA Logo URL
  """
  @spec mbta_logo() :: iodata
  def mbta_logo do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/t-logo@2x.png")
  end

  def manage_subscriptions_url(), do: Helpers.trip_url(ConciergeSite.Endpoint, :index)

  def feedback_url do
    case ConfigHelper.get_string(:feedback_url, :concierge_site) do
      "" -> nil
      nil -> nil
      url -> url
    end
  end

  @spec rating_base_url(String.t(), String.t()) :: iodata
  def rating_base_url(alert_id, user_id) do
    Helpers.static_url(
      ConciergeSite.Endpoint,
      "/feedback?alert_id=#{alert_id}&user_id=#{user_id}&rating="
    )
  end

  def reset_password_url(reset_token) do
    Helpers.password_reset_url(ConciergeSite.Endpoint, :edit, reset_token)
  end
end
