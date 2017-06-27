defmodule ConciergeSite.CommuterRailSubscriptionView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.Model.Trip

  @type trip_type :: :one_way | :round_trip

  @disabled_progress_bar_links %{trip_info: [:trip_info, :train, :preferences],
  train: [:train, :preferences],
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

  def trip_info_description(_trip_type) do
    ""
  end

  @doc """
  Returns stringified times to populate a dropdown list of a full day of times at
  fifteen-minute intervals
  """
  def travel_time_options() do
    0
    |> Stream.iterate(&(&1 + 900))
    |> Stream.map(&Calendar.Time.from_second_in_day/1)
    |> Stream.map(& {Calendar.Strftime.strftime!(&1, "%I:%M %p"), Calendar.Strftime.strftime!(&1, "%H:%M:%S")})
    |> Enum.take(96)
  end

  @spec trip_option(Trip.t, Trip.t) :: {:safe, iodata}
  def trip_option(trip, closest_trip) do
    content_tag :div, class: trip_option_classes(trip, closest_trip) do
      [
        trip_option_checkbox(trip, closest_trip),
        content_tag :label, class: "trip-option-description", for: "trip_#{trip.trip_number}" do
          trip_option_description(trip)
        end
      ]
    end
  end

  defp trip_option_classes(trip, closest_trip) do
    if closest_trip.trip_number == trip.trip_number do
      "trip-option closest-trip"
    else
      "trip-option"
    end
  end

  defp trip_option_checkbox(trip, closest_trip) do
    tag(:input,
        type: "checkbox",
        class: "trip-option-input",
        name: "subscription[trips][]",
        id: "trip_#{trip.trip_number}",
        value: trip.trip_number,
        checked: closest_trip.trip_number == trip.trip_number)
  end

  defp trip_option_description(trip) do
    {origin_name, _} = trip.origin
    {destination_name, _} = trip.destination

    [
      trip.route.long_name,
      " ",
      trip.trip_number,
      " | Departs ",
      origin_name,
      " at ",
      format_schedule_time(trip.departure_time),
      ", arrives at ",
      destination_name,
      " at ",
      format_schedule_time(trip.arrival_time)
    ]
  end

  defp format_schedule_time(time) do
    {:ok, time_string} = Calendar.Strftime.strftime(time, "%l:%M%P")
    time_string
  end
end
