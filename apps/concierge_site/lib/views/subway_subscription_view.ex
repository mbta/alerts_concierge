defmodule ConciergeSite.SubwaySubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.SubscriptionViewHelper,
    only: [joined_day_list: 1, travel_time_options: 0, format_time: 1]
  alias AlertProcessor.Helpers.StringHelper
  alias AlertProcessor.Helpers.DateTimeHelper

  @typedoc """
  Possible values for trip types in Create Subscription flow
  """
  @type trip_type :: :one_way | :round_trip | :roaming

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
  def trip_summary_title(params = %{"trip_type" => "one_way"}, station_names) do
    ["One way ",
     joined_day_list(params),
     " travel between ",
     station_names["origin"],
     " and ",
     station_names["destination"]]
  end

  def trip_summary_title(params = %{"trip_type" => "round_trip"}, station_names) do
    ["Round trip ",
     joined_day_list(params),
     " travel between ",
     station_names["origin"],
     " and ",
     station_names["destination"]]
  end

  def trip_summary_title(params = %{"trip_type" => "roaming"}, station_names) do
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
  def trip_summary_logistics(params = %{"trip_type" => "one_way"}, station_names) do
     [[format_time(params["departure_start"]),
      " - ",
      format_time(params["departure_end"]),
      " from ",
      station_names["origin"],
      " to ",
      station_names["destination"]]]
  end

  def trip_summary_logistics(params = %{"trip_type" => "round_trip"}, station_names) do
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

  def trip_summary_logistics(params = %{"trip_type" => "roaming"}, _station_names) do
    [[format_time(params["departure_start"]),
     " - ",
     format_time(params["departure_end"])]]
  end

  @doc """
  Converts a utc timestamp to local time stringifiied in the H:M:S format
  """
  @spec time_option_local_strftime(Time.t) :: String.t
  def time_option_local_strftime(timestamp) do
    timestamp
    |> DateTimeHelper.utc_time_to_local()
    |> Calendar.Strftime.strftime!("%H:%M:%S")
  end
end
