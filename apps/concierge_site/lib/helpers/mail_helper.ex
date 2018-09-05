defmodule ConciergeSite.Helpers.MailHelper do
  @moduledoc """
  Functions to use in rendering dynamically generated properties on
  digest emails
  """

  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  alias AlertProcessor.Model.{Alert, InformedEntity}
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
  For a given alert, returns the icon URL of it's route_type
  """
  @spec logo_for_alert(Alert.t()) :: iodata
  def logo_for_alert(%Alert{informed_entities: [ie | _]}) do
    logo_for_route_type(ie)
  end

  @doc """
  Return the MBTA Logo URL
  """
  @spec mbta_logo() :: iodata
  def mbta_logo do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/t-logo@2x.png")
  end

  @spec logo_for_route_type(InformedEntity.t()) :: iodata
  defp logo_for_route_type(%InformedEntity{route_type: 0, route: r}) do
    logo_for_subway(r)
  end

  defp logo_for_route_type(%InformedEntity{route_type: 1, route: r}) do
    logo_for_subway(r)
  end

  defp logo_for_route_type(%InformedEntity{route_type: 2}) do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_commuter.png")
  end

  defp logo_for_route_type(%InformedEntity{route_type: 3}) do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_bus.png")
  end

  defp logo_for_route_type(%InformedEntity{route_type: 4}) do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_ferry.png")
  end

  defp logo_for_route_type(%InformedEntity{facility_type: ft}) when not is_nil(ft) do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_facility.png")
  end

  defp logo_for_route_type(%InformedEntity{facility_type: ft}) when not is_nil(ft) do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_facility.png")
  end

  defp logo_for_route_type(_) do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_facility.png")
  end

  defp logo_for_subway("Red"),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_red-line.png")

  defp logo_for_subway("Mattapan"),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_red-line.png")

  defp logo_for_subway("Orange"),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_orange-line.png")

  defp logo_for_subway("Blue"),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_blue-line.png")

  defp logo_for_subway("Green-B"),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_green-line.png")

  defp logo_for_subway("Green-C"),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_green-line.png")

  defp logo_for_subway("Green-D"),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_green-line.png")

  defp logo_for_subway("Green-E"),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_green-line.png")

  defp logo_for_subway(nil),
    do: Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/icn_facility.png")

  def manage_subscriptions_url(), do: Helpers.trip_url(ConciergeSite.Endpoint, :index)

  def feedback_url do
    case ConfigHelper.get_string(:feedback_url, :concierge_site) do
      "" -> nil
      nil -> nil
      url -> url
    end
  end

  def reset_password_url(reset_token) do
    Helpers.password_reset_url(ConciergeSite.Endpoint, :edit, reset_token)
  end
end
