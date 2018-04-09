defmodule ConciergeSite.StopSelectHelper do

  @type stop_row :: [id: String.t, name: String.t, modes: MapSet.t, accessible: boolean]

  alias AlertProcessor.ServiceInfoCache
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  @spec render(String.t, atom, atom, [String.t], keyword) :: Phoenix.HTML.safe
  def render(route_id, input_name, field, selected \\ [], attrs \\ []) do
    default = if attrs[:no_default] == true, do: [], else: default_option()
    content_tag :select, attributes(input_name, field, attrs) do
      for stop <- get_stops_by_route(route_id), into: [default], do: render_option(stop, selected)
    end
  end

  @spec default_option() :: Phoenix.HTML.safe
  defp default_option() do
    content_tag :option, value: "", disabled: "disabled", selected: "selected" do
      "Select a stop"
    end
  end

  @spec render_option(stop_row, [String.t]) :: Phoenix.HTML.safe
  defp render_option([id: id, name: name, modes: modes, accessible: accessible], selected) do
    selected = if Enum.member?(selected, id), do: [selected: "selected"], else: []
    attributes = [value: id, data: option_data(modes, accessible)] ++ selected
    content_tag :option, attributes do
      name
    end
  end

  @spec option_data([integer], boolean) :: Keyword.t
  defp option_data(modes, accessible) do
    Enum.reduce(modes, [accessible: to_string(accessible)], fn(route_type, acc) ->
      Keyword.put(acc, route_type, true)
    end)
  end

  @spec get_stops_by_route(String.t) :: [stop_row]
  defp get_stops_by_route("*") do
    :subway
    |> get_routes()
    |> Kernel.++(get_routes(:cr))
    |> Kernel.++(get_routes(:ferry))
    |> Enum.flat_map(& get_stops_by_route(&1))
    |> Enum.uniq_by(& &1)
  end
  defp get_stops_by_route(route_id) do
    {:ok, stops_with_icons} = ServiceInfoCache.get_stops_with_icons()
    route_stops = route_id
    |> get_stop_list()
    |> Enum.sort_by(fn({name, _, _, _}) -> name end)

    for {name, id, _, _} <- route_stops do
      stops_with_icons[id]
      |> Keyword.put(:name, name)
      |> Keyword.put(:id, id)
    end
  end

  @spec get_stop_list(String.t) :: [tuple]
  defp get_stop_list("Green") do
    with {:ok, %{stop_list: b_stops}} = ServiceInfoCache.get_route("Green-B"),
         {:ok, %{stop_list: c_stops}} = ServiceInfoCache.get_route("Green-C"),
         {:ok, %{stop_list: d_stops}} = ServiceInfoCache.get_route("Green-D"),
         {:ok, %{stop_list: e_stops}} = ServiceInfoCache.get_route("Green-E") do
      Enum.uniq_by(b_stops ++ c_stops ++ d_stops ++ e_stops, & &1)
    end
  end
  defp get_stop_list(route_id), do: with {:ok, %{stop_list: stops}} = ServiceInfoCache.get_route(route_id), do: stops

  @spec attributes(atom, atom, keyword) :: keyword(String.t)
  defp attributes(input_name, field, attrs) do
    name = if attrs[:multiple] == "multiple", do: "#{input_name}[#{field}][]", else: "#{input_name}[#{field}]"
    [data: [type: "stop"], class: "form-control", id: "#{input_name}_#{field}", name: name]
    |> Keyword.merge(attrs)
  end

  @spec get_routes(atom) :: [String.t]
  defp get_routes(:subway), do: ["Red", "Orange", "Green", "Blue", "Mattapan"]
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
