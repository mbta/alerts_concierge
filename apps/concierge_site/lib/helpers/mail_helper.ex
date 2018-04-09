defmodule ConciergeSite.Helpers.MailHelper do
  @moduledoc """
  Functions to use in rendering dynamically generated properties on
  digest emails
  """

  @template_dir Application.get_env(:concierge_site, :mail_template_dir)

  alias AlertProcessor.Model.{Alert, InformedEntity}
  alias ConciergeSite.Auth.Token
  alias ConciergeSite.Router.Helpers
  alias AlertProcessor.Helpers.ConfigHelper
  require EEx

  EEx.function_from_file(
    :def,
    :html_footer,
    Path.join(@template_dir, "_footer.html.eex"),
    [:unsubscribe_url, :manage_subscriptions_url, :feedback_url]
  )

  EEx.function_from_file(
    :def,
    :text_footer,
    Path.join(@template_dir, "_footer.txt.eex"),
    [:unsubscribe_url, :manage_subscriptions_url, :feedback_url]
  )

  EEx.function_from_file(
    :def,
    :html_header,
    Path.join(@template_dir, "_header.html.eex"),
    []
  )

  @doc """
  For a given alert, returns the icon URL of it's route_type
  """
  @spec logo_for_alert(Alert.t) :: iodata
  def logo_for_alert(%Alert{informed_entities: [ie | _]}) do
    logo_for_route_type(ie)
  end

  @doc """
  For a given alert, return the alt text of it's route_type
  """
  @spec alt_text_for_alert(Alert.t) :: iodata
  def alt_text_for_alert(%Alert{informed_entities: [ie | _]}) do
    alt_text_for_route_type(ie)
  end

  @doc """
  Return the MBTA Logo URL
  """
  @spec mbta_logo() :: iodata
  def mbta_logo do
    Helpers.static_url(ConciergeSite.Endpoint, "/images/icons/t-logo@2x.png")
  end

  @spec logo_for_route_type(InformedEntity.t) :: iodata
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

  @spec alt_text_for_route_type(InformedEntity.t) :: iodata
  defp alt_text_for_route_type(%InformedEntity{route_type: 0, route: r}), do: alt_text_for_subway(r)
  defp alt_text_for_route_type(%InformedEntity{route_type: 1, route: r}), do: alt_text_for_subway(r)
  defp alt_text_for_route_type(%InformedEntity{route_type: 2}), do: "logo-commuter-rail"
  defp alt_text_for_route_type(%InformedEntity{route_type: 3}), do: "logo-bus"
  defp alt_text_for_route_type(%InformedEntity{route_type: 4}), do: "logo-ferry"
  defp alt_text_for_route_type(%InformedEntity{facility_type: ft}) when not is_nil(ft), do: "logo-facility"
  defp alt_text_for_route_type(_), do: "logo-facility"

  defp alt_text_for_subway(route) do
    case route do
      "Red" -> "logo-red-line"
      "Mattapan" -> "logo-red-line"
      "Orange" -> "logo-orange-line"
      "Blue" -> "logo-blue-line"
      "Green-B" -> "logo-green-line"
      "Green-C" -> "logo-green-line"
      "Green-D" -> "logo-green-line"
      "Green-E" -> "logo-green-line"
      nil -> "logo-mbta"
    end
  end

  def unsubscribe_url(user) do
    {:ok, token, _permissions} = Token.issue(user, [:unsubscribe], {30, :days})
    Helpers.unsubscribe_url(ConciergeSite.Endpoint, :unsubscribe, token)
  end

  def reset_password_url(password_reset_id) do
    Helpers.password_reset_url(ConciergeSite.Endpoint, :edit, password_reset_id)
  end

  def manage_subscriptions_url(user) do
    {:ok, token, _permissions} = Token.issue(user, [:manage_subscriptions], {30, :days})
    Helpers.v2_trip_url(ConciergeSite.Endpoint, :index, token: token)
  end

  def feedback_url do
    case ConfigHelper.get_string(:feedback_url, :concierge_site) do
      "" -> nil
      nil -> nil
      url -> url
    end
  end
end
