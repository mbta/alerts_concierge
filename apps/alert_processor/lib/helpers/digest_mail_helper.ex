defmodule AlertProcessor.DigestMailHelper do
  @moduledoc """
  Functions to use in rendering dynamically generated properties on
  digest emails
  """

  @asset_url Application.get_env(:alert_processor, :asset_url)
  @commuter_rail "#{@asset_url}/icons/commuter-rail.png"
  @bus "#{@asset_url}/icons/bus.png"
  @ferry "#{@asset_url}/icons/ferry.png"
  @logo "#{@asset_url}/icons/t-logo@2x.png"
  @red "#{@asset_url}/icons/icn_red-line.png"
  @blue "#{@asset_url}/icons/icn_blue-line.png"
  @orange "#{@asset_url}/icons/icn_orange-line.png"
  @green "#{@asset_url}/icons/icn_green-line.png"

  alias AlertProcessor.Model.{Alert, InformedEntity}

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
    @logo
  end

  @spec logo_for_route_type(InformedEntity.t) :: iodata
  defp logo_for_route_type(%InformedEntity{route_type: 0, route: r}), do: logo_for_subway(r)
  defp logo_for_route_type(%InformedEntity{route_type: 1, route: r}), do: logo_for_subway(r)
  defp logo_for_route_type(%InformedEntity{route_type: 2}), do: @commuter_rail
  defp logo_for_route_type(%InformedEntity{route_type: 3}), do: @bus
  defp logo_for_route_type(%InformedEntity{route_type: 4}), do: @ferry

  defp logo_for_subway(route) do
    case route do
      "Red" -> @red
      "Mattapan" -> @red
      "Orange" -> @orange
      "Blue" -> @blue
      "Green-B" -> @green
      "Green-C" -> @green
      "Green-D" -> @green
      "Green-E" -> @green
    end
  end

  @spec alt_text_for_route_type(InformedEntity.t) :: iodata
  defp alt_text_for_route_type(%InformedEntity{route_type: 0, route: r}), do: alt_text_for_subway(r)
  defp alt_text_for_route_type(%InformedEntity{route_type: 1, route: r}), do: alt_text_for_subway(r)
  defp alt_text_for_route_type(%InformedEntity{route_type: 2}), do: "logo-commuter-rail"
  defp alt_text_for_route_type(%InformedEntity{route_type: 3}), do: "logo-bus"
  defp alt_text_for_route_type(%InformedEntity{route_type: 4}), do: "logo-ferry"

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
    end
  end
end
