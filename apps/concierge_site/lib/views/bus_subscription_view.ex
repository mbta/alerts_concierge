defmodule ConciergeSite.BusSubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.SubscriptionViewHelper,
    only: [atomize_keys: 1, joined_day_list: 1, travel_time_options: 0,
           time_option_local_strftime: 1, format_time: 1]

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
  Returns a summary of a subscription's associated trip days, times, and stops
  """
  @spec trip_summary_title(map) :: iodata
  def trip_summary_title(params = %{"trip_type" => "one_way"}) do
    ["One way ",
     joined_day_list(params),
     " travel on the ",
     name_from_route(params["route"]),
    " bus:"]
  end

  def trip_summary_title(params = %{"trip_type" => "round_trip"}) do
    ["Round trip ",
     joined_day_list(params),
     " travel on the ",
    name_from_route(params["route"]),
    " bus:"]
  end

  defp name_from_route(route) do
    route
    |> String.split(" - ")
    |> List.first
  end

  defp direction_from_route(route) do
    route
    |> String.split(" - ")
    |> List.last
    |> named_direction()
  end

  def trip_summary_routes(params = %{"trip_type" => "round_trip"}) do
    [
      departure_format(params),
      return_format(params)
    ]
  end

  def trip_summary_routes(params = %{"trip_type" => "one_way"}) do
    [departure_format(params)]
  end

  defp departure_format(params) do
    [format_time(params["departure_start"]), " - ", format_time(params["departure_end"]), " | ", direction_from_route(params["route"])]
  end

  defp return_format(params) do
    direction = direction_from_route(params["route"])
    [format_time(params["return_start"]), " - ", format_time(params["return_end"]), " | ", reverse_direction(direction)]
  end

  defp reverse_direction("Inbound"), do: "Outbound"
  defp reverse_direction("Outbound"), do: "Inbound"

  defp named_direction("0"), do: "Outbound"
  defp named_direction("1"), do: "Inbound"
end
