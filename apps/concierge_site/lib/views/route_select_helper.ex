defmodule ConciergeSite.RouteSelectHelper do

  @type route_row :: {atom, String.t, String.t}

  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.Route
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  @spec render() :: Phoenix.HTML.safe
  def render() do
    content_tag :select, data: [type: "route"], class: "form-control" do
      [default_option(),
       option_group("Subway", get_routes(:subway)),
       option_group("Commuter Rail", get_routes(:cr)),
       option_group("Ferry", get_routes(:ferry)),
       option_group("Bus", get_routes(:bus))]
    end
  end

  @spec default_option() :: Phoenix.HTML.safe
  defp default_option() do
    content_tag :option, value: "", disabled: "disabled", selected: "selected" do
      "Select a subway, commuter rail, ferry or bus route"
    end
  end

  @spec option_group(String.t, [route_row]) :: Phoenix.HTML.safe
  defp option_group(label, options) do
    content_tag :optgroup, label: label do
      for {icon, id, name} <- options do
        content_tag :option, value: id, data: [icon: icon] do
          name
        end
      end
    end
  end

  @spec get_routes(atom) :: [route_row]
  defp get_routes(:subway) do
    [{:red, "Red", "Red Line"},
     {:orange, "Orange", "Orange Line"},
     {:green, "Green", "Green Line"},
     {:blue, "Blue", "Blue Line"},
     {:mattapan, "Mattapan", "Mattapan Trolley"}]
  end
  defp get_routes(:cr) do
    with {:ok, routes} <- ServiceInfoCache.get_commuter_rail_info() do
      for route <- routes do
        {:cr, route.route_id, Route.name(route)}
      end
    end
  end
  defp get_routes(:ferry) do
    with {:ok, routes} <- ServiceInfoCache.get_ferry_info() do
      for route <- routes do
        {:ferry, route.route_id, Route.name(route)}
      end
    end
  end
  defp get_routes(:bus) do
    with {:ok, routes} <- ServiceInfoCache.get_bus_info() do
      Enum.flat_map(routes, fn(route) ->
        [bus_route(route, "1"),
         bus_route(route, "0")]
      end)
    end
  end

  @spec bus_route(Route.t, String.t) :: route_row
  defp bus_route(route, direction_id) do
    {:bus, "#{route.route_id} - #{direction_id}",
           "Route #{Route.name(route)} - #{headsign(route, direction_id)}"}
  end

  @spec headsign(Route.t, String.t) :: [String.t]
  defp headsign(%Route{headsigns: %{0 => signs}}, "0"), do: [Enum.join(signs, ", "), " - Outbound"]
  defp headsign(%Route{headsigns: %{1 => signs}}, "1"), do: [Enum.join(signs, ", "), " - Inbound"]
  defp headsign(_, "0"), do: ["Outbound"]
  defp headsign(_, "1"), do: ["Inbound"]
end
