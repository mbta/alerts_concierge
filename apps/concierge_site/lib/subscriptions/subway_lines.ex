defmodule ConciergeSite.Subscriptions.SubwayLines do
  @moduledoc """
  Module for transforming ServiceInfoCache subway info
  """

  @doc """
  Transform AlertProcessor.Model.Route struct into keyword list of {"Line Name", [Stations]}

  The Red Line is ordered by Braintree stops, Ashmont stops, then the remaining
  stops common to both Red Line branches.

  For use in the Phoenix.HTML.Form.select helper, so that the line name can
  become the label of an <optgroup> containing <option>s for each station.
  """

  @spec station_list_select_options(%AlertProcessor.Model.Route{}) :: [{String.t, list}]
  def station_list_select_options(routes) do
    [red_line_ashmont | [red_line_braintree | remaining_routes]] = routes

    red_line = map_redline_stations(red_line_ashmont, red_line_braintree)

    station_list = Enum.map(remaining_routes, fn(route) ->
      {route.long_name, route.stop_list}
    end)

    [red_line | station_list]
  end

  defp map_redline_stations(red_line_ashmont, red_line_braintree) do
    red_line_stations =
      red_line_braintree.stop_list
      |> braintree_stations_subset
      |> Enum.reverse
      |> Enum.concat(red_line_ashmont.stop_list)

    {"Red Line", red_line_stations}
  end

  defp braintree_stations_subset(stop_list) do
    do_braintree_stations_subset(stop_list, [])
  end

  defp do_braintree_stations_subset([{"North Quincy", "place-nqncy"} | _common_red_line_stops], acc) do
    [{"North Quincy", "place-nqncy"} | acc]
  end

  defp do_braintree_stations_subset([stop | stop_list], acc) do
    next_acc = [stop | acc]
    do_braintree_stations_subset(stop_list, next_acc)
  end
end
