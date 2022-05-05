defmodule ConciergeSite.Helpers.MailHelper do
  @moduledoc """
  Functions to use in rendering dynamically generated properties on
  digest emails
  """

  alias AlertProcessor.Model.Notification
  import ConciergeSite.ViewHelpers, only: [external_url: 1]
  alias ConciergeSite.Router.Helpers
  require EEx

  @all_alerts_url external_url(:alerts)
  @support_url external_url(:support)

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

  @spec track_open_url(Notification.t()) :: String.t()
  def track_open_url(%Notification{id: notification_id, alert_id: alert_id}) do
    Helpers.email_opened_url(ConciergeSite.Endpoint, :notification, alert_id, notification_id)
  end
end
