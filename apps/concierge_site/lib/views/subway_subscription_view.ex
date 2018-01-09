defmodule ConciergeSite.SubwaySubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.TimeHelper,
    only: [travel_time_options: 0, format_time_string: 1, time_to_string: 1]
  import ConciergeSite.SubscriptionHelper,
    only: [joined_day_list: 1, atomize_keys: 1, progress_link_class: 3,
           do_query_string_params: 2, selected_relevant_days: 1]

  @type step :: :trip_type | :trip_info | :preferences

  @disabled_progress_bar_links %{trip_info: [:trip_info, :preferences],
    preferences: [:preferences]}

  defdelegate progress_step_classes(page, step), to: ConciergeSite.SubscriptionHelper

  def progress_link_class(page, step), do: progress_link_class(page, step, @disabled_progress_bar_links)

  @doc """
  constructs keyword list of parameters to pass along relevant parameters to next or previous step
  via get request
  """
  @spec query_string_params(step, map | nil) :: keyword(String.t)
  def query_string_params(step, params), do: do_query_string_params(params, params_for_step(step))

  @doc """
  returns list of parameters that should be present and passed along
  from the step given.
  """
  @spec params_for_step(step) :: [String.t]
  def params_for_step(:trip_type), do: ~w(trip_type)
  def params_for_step(:trip_info), do: [
    "origin", "destination", "departure_start", "departure_end", "return_start", "return_end",
    "weekday", "saturday", "sunday" | params_for_step(:trip_type)
  ]
  def params_for_step(:preferences), do: ["alert_priority_type" | params_for_step(:trip_info)]
  def params_for_step(_), do: []

  @doc """
  Returns a summary of a subscription's associated trip days, times, and stops
  """
  @spec trip_summary_title(map, map) :: iodata
  def trip_summary_title(params, station_names) do
    [format_trip_type(params["trip_type"]),
     " travel between ",
     station_names["origin"],
     " and ",
     station_names["destination"],
     " on ",
     joined_day_list(params)]
  end

  @spec format_trip_type(String.t) :: String.t
  defp format_trip_type("one_way"), do: "One way"
  defp format_trip_type("round_trip"), do: "Round trip"
  defp format_trip_type("roaming"), do: "General"

  @doc """
  Returns a list of a subscription's associated times and stops
  """
  @spec trip_summary_logistics(map, map) :: [iodata]
  def trip_summary_logistics(%{"trip_type" => "one_way"} = params, station_names) do
     [[format_time_string(params["departure_start"]),
      " - ",
      format_time_string(params["departure_end"]),
      " from ",
      station_names["origin"],
      " to ",
      station_names["destination"]]]
  end

  def trip_summary_logistics(%{"trip_type" => "round_trip"} = params, station_names) do
    [[format_time_string(params["departure_start"]),
      " - ",
      format_time_string(params["departure_end"]),
      " from ",
      station_names["origin"],
      " to ",
      station_names["destination"]],
     [format_time_string(params["return_start"]),
      " - ",
      format_time_string(params["return_end"]),
      " from ",
      station_names["destination"],
      " to ",
      station_names["origin"]]]
  end

  def trip_summary_logistics(%{"trip_type" => "roaming"} = params, _station_names) do
    [[format_time_string(params["departure_start"]),
     " - ",
     format_time_string(params["departure_end"])]]
  end

  def default_severity_selection("roaming"), do: :high
  def default_severity_selection(_), do: :medium

  def origin_label("roaming"), do: "Station 1"
  def origin_label(_), do: "Origin"

  def destination_label("roaming"), do: "Station 2"
  def destination_label(_), do: "Destination"
end
