defmodule ConciergeSite.Subscriptions.BusRoutes do
  @moduledoc """
  Module for transforming ServiceInfoCache bus info
  """

  @doc """
  Transform AlertProcessor.Model.Route struct into keyword list of {"Route Name", [Routes]}

  For use in the Phoenix.HTML.Form.select helper, so that the route name can
  become the label of an <optgroup> containing <option>s for each route.
  """

  @spec route_list_select_options([%AlertProcessor.Model.Route{}]) :: [{String.t, list}]
  def route_list_select_options(routes) do
    Enum.flat_map(routes, fn(route) ->
      [route.long_name <> " - Inbound", route.long_name <> " - Outbound"]
    end)
  end
end
