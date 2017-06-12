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
    Enum.map(routes, fn(route) ->
      [{first_stop_name, first_stop_code} | _stops] = route.stop_list

      route_name =
        case {first_stop_name, first_stop_code, route.long_name} do
          {"Ashmont", "place-asmnl", "Red Line"} ->
            "Red Line Ashmont"
          {"Braintree", "place-brntn", "Red Line"} ->
            "Red Line Braintree"
          {_stop_name, _stop_code, _route_name} ->
            route.long_name
        end
      {route_name, route.stop_list}
    end)
  end
end
