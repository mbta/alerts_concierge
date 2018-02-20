defmodule ConciergeSite.Subscriptions.BusRoutes do
  @moduledoc """
  Module for transforming ServiceInfoCache bus info
  """

  alias AlertProcessor.Model.Route
  @doc """
  Transform AlertProcessor.Model.Route struct into keyword list of {"Route Name", [Routes]}

  For use in the Phoenix.HTML.Form.select helper, so that the route name can
  become the label of an <optgroup> containing <option>s for each route.
  """

  @spec route_list_select_options([%Route{}]) :: Keyword.t
  def route_list_select_options(routes) do
    Enum.flat_map(routes, fn(route) ->
      [
        route_list_select_option(route, "1"),
        route_list_select_option(route, "0")
      ]
    end)
  end

  @spec route_list_select_option(%Route{}, String.t) :: {String.t, String.t}
  def route_list_select_option(route, direction_id_str) do
    {
      "Route #{Route.name(route)} - #{headsign(route, direction_id_str)}",
      "#{route.route_id} - #{direction_id_str}"
    }
  end

  defp headsign(%Route{headsigns: %{0 => signs}}, "0") do
    Enum.join(signs, ", ")
  end
  defp headsign(%Route{headsigns: %{1 => signs}}, "1") do
    Enum.join(signs, ", ")
  end
  defp headsign(_, "0") do
    "Outbound"
  end
  defp headsign(_, "1") do
    "Inbound"
  end
end
