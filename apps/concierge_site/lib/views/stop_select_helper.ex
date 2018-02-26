defmodule ConciergeSite.StopSelectHelper do

  @type stop_row :: [id: String.t, name: String.t, modes: [String.t], accessible: boolean]

  alias AlertProcessor.ServiceInfoCache
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  @spec render(String.t, atom, atom) :: Phoenix.HTML.safe
  def render(route_id, input_name, field) do
    content_tag :select, attributes(input_name, field) do
      for stop <- get_stops_by_route(route_id), into: [default_option()], do: render_option(stop)
    end
  end

  @spec default_option() :: Phoenix.HTML.safe
  defp default_option() do
    content_tag :option, value: "", disabled: "disabled", selected: "selected" do
      "Select a stop"
    end
  end

  @spec render_option(stop_row) :: Phoenix.HTML.Tag
  defp render_option([id: id, name: name, modes: modes, accessible: accessible]) do
    [content_tag :option, value: id, data: option_data(modes, accessible) do
      name
    end]
  end

  @spec option_data([integer], boolean) :: Keyword.t
  defp option_data(modes, accessible) do
    Enum.reduce(modes, [accessible: to_string(accessible)], fn(route_type, acc) ->
      Keyword.put(acc, route_type, true)
    end)
  end

  @spec get_stops_by_route(String.t) :: [stop_row]
  defp get_stops_by_route(route_id) do
    {:ok, stops_with_icons} = ServiceInfoCache.get_stops_with_icons()
    route_stops = get_stop_list(route_id)
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
      b_stops ++ c_stops ++ d_stops ++ e_stops
    end
  end
  defp get_stop_list(route_id), do: with {:ok, %{stop_list: stops}} = ServiceInfoCache.get_route(route_id), do: stops

  @spec attributes(atom, atom) :: keyword(String.t)
  defp attributes(input_name, field) do
    [data: [type: "stop"],
     class: "form-control",
     id: "#{input_name}_#{field}",
     name: "#{input_name}[#{field}]"]
  end
end
