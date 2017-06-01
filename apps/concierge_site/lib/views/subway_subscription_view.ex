defmodule ConciergeSite.SubwaySubscriptionView do
  use ConciergeSite.Web, :view

  @disabled_progress_bar_links %{trip_info: [:trip_info, :preferences],
    preferences: [:preferences]}

  @doc """
  Provide css class to disable links within the subscription flow progress
  bar
  """
  def progress_link_class(:trip_type, _step), do: "disabled-progress-link"

  def progress_link_class(page, step) do
    if @disabled_progress_bar_links |> Map.get(page) |> Enum.member?(step) do
      "disabled-progress-link"
    end
  end

  @doc """
  Provide css classes for the text and circle in progress bar steps
  """
  def progress_step_classes(page, step) when (page == step) do
    %{circle: "active-circle", name: "active-page"}
  end

  def progress_step_classes(_page, _step) do
    %{}
  end

  @doc """
  Provide description text for Trip Info page based on which trip type selected
  """
  def trip_info_description("one-way") do
    "Please note: We will only send you alerts about service updates that affect your origin and destination stations."
  end

  def trip_info_description("round-trip") do
    trip_info_description("one-way")
      |> String.trim_trailing(".")
      |> Kernel.<>(", in both directions.")
  end

  def trip_info_description("roaming") do
    "We will send you alerts and service updates that affect all stations along your specified route."
  end

  def trip_info_description(_) do
    ""
  end

  @doc """
  Transform station map to be select helper friendly
  """
  def station_list_select_options(stations) do
    Enum.map(stations, fn({line, station_list}) ->
      {elem(line, 0), station_list}
    end)
  end

  @doc """
  Transform station map into tuples for typeahead options
  """
  def station_suggestion_options(stations) do
    Enum.to_list(stations)
    |> map_lines_to_stations
    |> List.flatten
    |> merge_lines
    |> Enum.sort
  end

  defp map_lines_to_stations(stations) do
    Enum.map(stations, fn(line) ->
      elem(line, 1) |> Enum.map(fn(stop) ->
        Tuple.append(stop, [elem(line, 0) |> elem(0)])
      end)
    end)
  end

  defp merge_lines(station_list) do
    station_list
    |> Enum.group_by(fn(station) -> elem(station, 0) end)
    |> Enum.map(fn({station_name, station_data}) ->
      {station_name, elem(List.first(station_data), 1), compact_line_names(station_data)}
    end)
  end

  defp compact_line_names(station_data) do
    Enum.map(station_data, fn(x) -> elem(x, 2) end)
    |> List.flatten
    |> Enum.map(fn(line) -> String.split(line, "-") |> List.first end)
    |> Enum.uniq
  end

  def station_attrs(station) do
    lines = elem(station, 2) |> Enum.map(&line_icon_attrs/1)

    %{name: elem(station, 0), lines: lines}
  end

  defp line_icon_attrs(line) do
    name = String.split(line, "-") |> List.first
    downcase_name = String.downcase(name)

    %{name: "#{name} Line",
      icon_circle_class: "icon-#{downcase_name}-line-circle"}
  end
end
