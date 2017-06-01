defmodule AlertProcessor.DigestMailHelper do
  @moduledoc """
  Functions to use in rendering dynamically generated properties on
  digest emails
  """

  @asset_url Application.get_env(:alert_processor, :asset_url)
  @commuter_rail "#{@asset_url}/icons/commuter-rail.png"
  @bus "#{@asset_url}/icons/bus.png"
  @ferry "#{@asset_url}/icons/ferry.png"
  @logo "#{@asset_url}/icons/icn_accessibility@2x.png"
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
    logo_for_route_type(ie.route_type, ie)
  end

  @doc """
  Return the MBTA Logo URL
  """
  @spec mbta_logo() :: iodata
  def mbta_logo do
    @logo
  end

  @spec logo_for_route_type(0..4, InformedEntity.t) :: iodata
  defp logo_for_route_type(route_type, informed_entity) do
    case route_type do
      0 -> logo_for_subway(informed_entity.route)
      1 -> logo_for_subway(informed_entity.route)
      2 -> @commuter_rail
      3 -> @bus
      4 -> @ferry
   end
  end

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
end
