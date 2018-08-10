defmodule ConciergeSite.RouteSelectHelper do
  @type route_row :: {atom, String.t(), String.t()}

  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.Route
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  @spec render(atom, atom, [String.t()], keyword) :: Phoenix.HTML.safe()
  def render(input_name, field, selected \\ [], attrs \\ []) do
    content_tag :select, attributes(input_name, field, attrs) do
      default = if attrs[:no_default] == true, do: [], else: default_option()
      bus_options = if attrs[:no_bus] == true, do: [], else: option_group("Bus", :bus, selected)
      subway_option = if attrs[:separate_green] == true, do: :subway_all_green, else: :subway

      [
        default,
        option_group("Subway", subway_option, selected),
        option_group("Commuter Rail", :cr, selected),
        option_group("Ferry", :ferry, selected),
        bus_options
      ]
    end
  end

  @spec attributes(atom, atom, keyword) :: keyword(String.t())
  defp attributes(input_name, field, attrs) do
    name =
      if attrs[:multiple] == "multiple",
        do: "#{input_name}[#{field}][]",
        else: "#{input_name}[#{field}]"

    [data: [type: "route"], class: "form-control", id: "#{input_name}_#{field}", name: name]
    |> Keyword.merge(attrs)
  end

  @spec default_option() :: Phoenix.HTML.safe()
  defp default_option() do
    content_tag :option, value: "", disabled: "disabled", selected: "selected" do
      "Select a subway, commuter rail, ferry or bus route"
    end
  end

  @spec option_group(String.t(), atom, [String.t()]) :: Phoenix.HTML.safe()
  defp option_group(label, mode, selected) do
    options = get_routes(mode)

    content_tag :optgroup, label: label do
      for {icon, id, name} <- options do
        value = value(id, name, mode)
        selected = if Enum.member?(selected, value), do: [selected: "selected"], else: []
        attrs = [value: value, data: [icon: icon]] ++ selected

        content_tag :option, attrs do
          name
        end
      end
    end
  end

  defp value(id, name, mode) do
    "#{id}~~#{name}~~#{mode}"
  end

  @spec get_routes(atom) :: [route_row]
  defp get_routes(:subway) do
    [
      {:red, "Red", "Red Line"},
      {:orange, "Orange", "Orange Line"},
      {:green, "Green", "Green Line"},
      {:blue, "Blue", "Blue Line"},
      {:mattapan, "Mattapan", "Mattapan Trolley"}
    ]
  end

  defp get_routes(:subway_all_green) do
    [
      {:red, "Red", "Red Line"},
      {:orange, "Orange", "Orange Line"},
      {:"green-b", "Green-B", "Green Line B"},
      {:"green-c", "Green-C", "Green Line C"},
      {:"green-d", "Green-D", "Green Line D"},
      {:"green-e", "Green-E", "Green Line E"},
      {:blue, "Blue", "Blue Line"},
      {:mattapan, "Mattapan", "Mattapan Trolley"}
    ]
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
      Enum.flat_map(routes, fn route ->
        [bus_route(route, "1"), bus_route(route, "0")]
      end)
    end
  end

  @spec bus_route(Route.t(), String.t()) :: route_row
  defp bus_route(route, direction_id) do
    {:bus, "#{route.route_id} - #{direction_id}",
     "Route #{Route.bus_short_name(route)} - #{headsign(route, direction_id)}"}
  end

  @spec headsign(Route.t(), String.t()) :: [String.t()]
  defp headsign(%Route{headsigns: %{0 => signs}}, "0"),
    do: [Enum.join(signs, ", "), " - Outbound"]

  defp headsign(%Route{headsigns: %{1 => signs}}, "1"), do: [Enum.join(signs, ", "), " - Inbound"]
  defp headsign(_, "0"), do: ["Outbound"]
  defp headsign(_, "1"), do: ["Inbound"]
end
