defmodule ConciergeSite.SubwaySubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.SubscriptionViewHelper,
    only: [joined_day_list: 1, travel_time_options: 0, format_time: 1,
           time_option_local_strftime: 1, atomize_keys: 1, progress_link_class: 3]

  @typedoc """
  Possible values for trip types in Create Subscription flow
  """
  @type trip_type :: :one_way | :round_trip | :roaming

  @disabled_progress_bar_links %{trip_info: [:trip_info, :preferences],
    preferences: [:preferences]}

  defdelegate progress_step_classes(page, step), to: ConciergeSite.SubscriptionViewHelper

  def progress_link_class(page, step), do: progress_link_class(page, step, @disabled_progress_bar_links)

  @doc """
  Provide description text for Trip Info page based on which trip type selected
  """

  @spec trip_info_description(trip_type) :: String.t
  def trip_info_description(:one_way) do
    "Please note: We will only send you alerts about service updates that affect your origin and destination stations."
  end

  def trip_info_description(:round_trip) do
    [
      :one_way |> trip_info_description |> String.trim_trailing("."),
      ", in both directions."
    ]
  end

  def trip_info_description(:roaming) do
    "We will send you alerts and service updates that affect all stations along your specified route."
  end

  def trip_info_description(_trip_type) do
    ""
  end

  @doc """
  Returns a summary of a subscription's associated trip days, times, and stops
  """
  @spec trip_summary_title(map, map) :: iodata
  def trip_summary_title(%{"trip_type" => "one_way"} = params, station_names) do
    ["One way ",
     joined_day_list(params),
     " travel between ",
     station_names["origin"],
     " and ",
     station_names["destination"]]
  end

  def trip_summary_title(%{"trip_type" => "round_trip"} = params, station_names) do
    ["Round trip ",
     joined_day_list(params),
     " travel between ",
     station_names["origin"],
     " and ",
     station_names["destination"]]
  end

  def trip_summary_title(%{"trip_type" => "roaming"} = params, station_names) do
    [params
     |> joined_day_list()
     |> String.capitalize(),
     " roaming travel between ",
     station_names["origin"],
     " and ",
     station_names["destination"]]
  end

  @doc """
  Returns a list of a subscription's associated times and stops
  """
  @spec trip_summary_logistics(map, map) :: [iodata]
  def trip_summary_logistics(%{"trip_type" => "one_way"} = params, station_names) do
     [[format_time(params["departure_start"]),
      " - ",
      format_time(params["departure_end"]),
      " from ",
      station_names["origin"],
      " to ",
      station_names["destination"]]]
  end

  def trip_summary_logistics(%{"trip_type" => "round_trip"} = params, station_names) do
    [[format_time(params["departure_start"]),
      " - ",
      format_time(params["departure_end"]),
      " from ",
      station_names["origin"],
      " to ",
      station_names["destination"]],
     [format_time(params["return_start"]),
      " - ",
      format_time(params["return_end"]),
      " from ",
      station_names["destination"],
      " to ",
      station_names["origin"]]]
  end

  def trip_summary_logistics(%{"trip_type" => "roaming"} = params, _station_names) do
    [[format_time(params["departure_start"]),
     " - ",
     format_time(params["departure_end"])]]
  end
end
