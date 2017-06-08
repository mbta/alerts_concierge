defmodule ConciergeSite.Subscriptions.SubwayLines do
  @moduledoc """
  Module for transforming ServiceInfoCache subway info
  """

  @doc """
  Transform AlertProcessor.Model.Route struct into keyword list of {"Line Name", [Stations]}

  For use in the Phoenix.HTML.Form.select helper, so that the line name can
  become the label of an <optgroup> containing <option>s for each station.
  """

  @spec station_list_select_options(%AlertProcessor.Model.Route{}) :: [{String.t, list}]
  def station_list_select_options(routes) do
    Enum.map(routes, fn(route) -> {route.route_id, route.stop_list} end)
  end
end
