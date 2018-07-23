defmodule ConciergeSite.RouteSelectHelperChoicesJS do
  @type route_row :: {atom, String.t(), String.t()}

  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.Route
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  @spec render(atom, atom, [String.t()], keyword) :: [Phoenix.HTML.safe()]
  def render(input_name, field, selected \\ [], attrs \\ []) do
    [
      content_tag :div, data: [type: "mode-select", id: "subway"] do
        content_tag :select, attributes(input_name, field, :subway, attrs, true) do
          options(:subway, selected)
        end
      end,
      content_tag :div, data: [type: "mode-select", id: "cr"], class: "d-none" do
        content_tag :select, attributes(input_name, field, :cr, attrs, false) do
          options(:cr, selected)
        end
      end,
      content_tag :div, data: [type: "mode-select", id: "ferry"], class: "d-none" do
        content_tag :select, attributes(input_name, field, :ferry, attrs, false) do
          options(:ferry, selected)
        end
      end,
      content_tag :div, data: [type: "mode-select", id: "bus"], class: "d-none" do
        content_tag :select, attributes(input_name, field, :bus, attrs, false) do
          options(:bus, selected)
        end
      end
    ]
  end

  @spec attributes(atom, atom, atom, keyword, boolean) :: keyword(String.t())
  defp attributes(input_name, field, mode, attrs, selected) do
    suffix = if selected, do: "", else: "-hidden"

    name =
      if attrs[:multiple] == "multiple",
        do: "#{input_name}#{suffix}[#{field}][]",
        else: "#{input_name}#{suffix}[#{field}]"

    [
      data: [type: "route"],
      class: "form-control",
      id: "#{input_name}_#{field}_#{mode}",
      name: name
    ]
    |> Keyword.merge(attrs)
  end

  @spec options(atom, [String.t()]) :: [Phoenix.HTML.safe()]
  defp options(mode, selected) do
    options = get_routes(mode)

    for {icon, id, name} <- options do
      value = value(id, name, mode)
      selected = if Enum.member?(selected, value), do: [selected: "selected"], else: []
      attrs = [value: value, data: [icon: icon]] ++ selected

      content_tag :option, attrs do
        name
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
      for route <- routes do
        {:bus, "#{route.route_id} - 1", "Route #{Route.name(route)}"}
      end
    end
  end
end
