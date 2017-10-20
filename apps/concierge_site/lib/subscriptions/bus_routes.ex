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
  def route_list_select_option(route, "0") do
    {:"Route #{Route.name(route)} - Outbound", "#{route.route_id} - 0"}
  end
  def route_list_select_option(route, "1") do
    {:"Route #{Route.name(route)} - Inbound", "#{route.route_id} - 1"}
  end
end
