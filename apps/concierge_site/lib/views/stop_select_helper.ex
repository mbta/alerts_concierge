defmodule ConciergeSite.StopSelectHelper do
  @type stop_row :: [
          id: String.t(),
          name: String.t(),
          modes: MapSet.t(),
          accessible: boolean,
          shapes: MapSet.t()
        ]

  alias AlertProcessor.ServiceInfoCache
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  @spec render(String.t(), atom, atom, [String.t()], keyword) :: Phoenix.HTML.safe()
  def render(route_id, input_name, field, selected \\ [], attrs \\ []) do
    default = if attrs[:no_default] == true, do: [], else: default_option()

    content_tag :select, attributes(input_name, field, route_id, attrs) do
      for stop <- get_stops_by_route(route_id), into: [default], do: render_option(stop, selected)
    end
  end

  @spec default_option() :: Phoenix.HTML.safe()
  defp default_option() do
    content_tag :option, value: "", disabled: "disabled", selected: "selected" do
      "Select a stop"
    end
  end

  @spec render_option(stop_row, [String.t()]) :: Phoenix.HTML.safe()
  defp render_option(
         [id: id, name: name, modes: modes, accessible: _accessible, shapes: shapes],
         selected
       ) do
    selected = if Enum.member?(selected, id), do: [selected: "selected"], else: []
    attributes = [value: id, data: option_data(modes) ++ option_data(shapes)] ++ selected

    content_tag :option, attributes do
      name
    end
  end

  @spec option_data([integer]) :: Keyword.t()
  defp option_data(modes) do
    Enum.reduce(modes, [], fn route_type, acc ->
      Keyword.put(acc, route_type, true)
    end)
  end

  @spec get_stops_by_route(String.t()) :: [stop_row]
  defp get_stops_by_route("*") do
    :subway
    |> get_routes()
    |> Kernel.++(get_routes(:cr))
    |> Kernel.++(get_routes(:ferry))
    |> Kernel.++(get_routes(:bus_silver_line))
    |> Enum.flat_map(&get_stops_by_route(&1))
    |> Enum.uniq_by(& &1)
  end

  defp get_stops_by_route(route_id) do
    with {:ok, stops_with_icons} = ServiceInfoCache.get_stops_with_icons(),
         {:ok, subway_lines} = ServiceInfoCache.get_subway_info() do
      red_line_shapes = get_redline_shapes(route_id, subway_lines)

      route_stops =
        route_id
        |> get_stop_list(subway_lines)
        |> Enum.sort_by(fn {name, _, _, _} -> name end)

      for {name, id, _, _} <- route_stops do
        stops_with_icons[id]
        |> Keyword.put(:name, name)
        |> Keyword.put(:id, id)
        |> add_redline_shapes(route_id, id, red_line_shapes)
      end
    end
  end

  defp add_redline_shapes(stop, "Red", stop_id, shapes),
    do: stop ++ [shapes: MapSet.new(shapes[stop_id])]

  defp add_redline_shapes(stop, _, _, _), do: stop ++ [shapes: MapSet.new()]

  defp get_redline_shapes("Red", subway_lines) do
    [shape_1, shape_2] =
      subway_lines
      |> Enum.filter(fn %{stop_list: [{_, first_stop_id, _, _} | _], route_id: route_id} ->
        route_id == "Red" && (first_stop_id == "place-asmnl" || first_stop_id == "place-brntn")
      end)
      |> Enum.map(fn %{stop_list: [{_, first_stop_id, _, _} | _] = stops} ->
        shape = if first_stop_id == "place-asmnl", do: [:red_1], else: [:red_2]
        Enum.reduce(stops, %{}, fn {_, stop_id, _, _}, acc -> Map.put(acc, stop_id, shape) end)
      end)

    Map.merge(shape_1, shape_2, fn _key, shape1, shape2 ->
      shape1 ++ shape2
    end)
  end

  defp get_redline_shapes(_, _), do: %{}

  @spec get_stop_list(String.t(), list) :: [tuple]
  defp get_stop_list("Green", _) do
    with {:ok, %{stop_list: b_stops}} = ServiceInfoCache.get_route("Green-B"),
         {:ok, %{stop_list: c_stops}} = ServiceInfoCache.get_route("Green-C"),
         {:ok, %{stop_list: d_stops}} = ServiceInfoCache.get_route("Green-D"),
         {:ok, %{stop_list: e_stops}} = ServiceInfoCache.get_route("Green-E") do
      Enum.uniq_by(b_stops ++ c_stops ++ d_stops ++ e_stops, & &1)
    end
  end

  defp get_stop_list("Red", subway_lines) do
    subway_lines
    |> Enum.flat_map(fn %{stop_list: stops, route_id: route_id} ->
      if route_id == "Red", do: stops, else: []
    end)
    |> Enum.uniq_by(& &1)
  end

  defp get_stop_list(route_id, _),
    do: with({:ok, %{stop_list: stops}} = ServiceInfoCache.get_route(route_id), do: stops)

  @spec attributes(atom, atom, String.t(), keyword) :: keyword(String.t())
  defp attributes(input_name, field, route_id, attrs) do
    name =
      if attrs[:multiple] == "multiple",
        do: "#{input_name}[#{field}][]",
        else: "#{input_name}[#{field}]"

    [
      data: [type: "stop", route: route_id],
      class: "form-control",
      id: "#{input_name}_#{field}",
      name: name
    ]
    |> Keyword.merge(attrs)
  end

  @spec get_routes(atom) :: [String.t()]
  defp get_routes(:subway), do: ["Red", "Orange", "Green", "Blue", "Mattapan"]
  defp get_routes(:bus_silver_line), do: ~w(741 742 743 749 751)

  defp get_routes(:cr) do
    with {:ok, routes} <- ServiceInfoCache.get_commuter_rail_info() do
      for route <- routes, do: route.route_id
    end
  end

  defp get_routes(:ferry) do
    with {:ok, routes} <- ServiceInfoCache.get_ferry_info() do
      for route <- routes, do: route.route_id
    end
  end
end
