defmodule ConciergeSite.Helpers.MailHelper do
  @moduledoc """
  Functions to use in rendering dynamically generated properties on
  digest emails
  """

  import ConciergeSite.ViewHelpers, only: [external_url: 1]
  alias ConciergeSite.Router.Helpers
  require EEx

  @all_alerts_url external_url(:alerts)
  @support_url external_url(:support)
  @template_dir Application.compile_env!(:concierge_site, :mail_template_dir)

  EEx.function_from_file(:def, :html_footer, Path.join(@template_dir, "_footer.html.eex"), [
    :manage_subscriptions_url,
    :support_url
  ])

  EEx.function_from_file(:def, :text_footer, Path.join(@template_dir, "_footer.txt.eex"), [
    :manage_subscriptions_url,
    :support_url
  ])

  EEx.function_from_file(:def, :html_header, Path.join(@template_dir, "_header.html.eex"), [])

  @doc """
  Return the MBTA Logo URL
  """
  @spec mbta_logo() :: iodata
  def mbta_logo do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/t-logo@2x.png")
  end

  def all_alerts_url, do: @all_alerts_url
  def support_url, do: @support_url
  def manage_subscriptions_url(), do: Helpers.trip_url(ConciergeSite.Endpoint, :index)

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
