defmodule ConciergeSite.CommuterRailSubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.SubscriptionViewHelper, only: [atomize_keys: 1, travel_time_options: 0]
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

  @spec trip_option(Trip.t, Trip.t, :depart | :return) :: Phoenix.HTML.safe
  def trip_option(trip, closest_trip, trip_type) do
    content_tag :div, class: trip_option_classes(trip, closest_trip) do
      [
        trip_option_checkbox(trip, closest_trip, trip_type),
        content_tag :label, class: "trip-option-description", for: trip_id_string(trip) do
          trip_option_description(trip)
        end
      ]
    end
  end

  defp trip_option_classes(%{trip_number: tn}, %{trip_number: tn}), do: "trip-option closest-trip"
  defp trip_option_classes(_, _), do: "trip-option"

  defp trip_option_checkbox(trip, closest_trip, trip_type) do
    tag(:input,
        type: "checkbox",
        class: "trip-option-input",
        name: trip_option_name(trip_type),
        id: trip_id_string(trip),
        value: trip.trip_number,
        checked: closest_trip.trip_number == trip.trip_number)
  end

  defp trip_option_name(:depart), do: "subscription[trips][]"
  defp trip_option_name(:return), do: "subscription[return_trips][]"

  defp trip_id_string(trip) do
    ["trip_", trip.trip_number]
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

  def trip_summary_header(subscription_params, {origin_name, _}, {destination_name, _}) do
    [
      trip_summary_header_trip_type(subscription_params),
      " ",
      trip_summary_header_relevant_days(subscription_params),
      " travel between ",
      origin_name,
      " and ",
      destination_name,
      ":"
    ]
  end
  defp trip_summary_header_trip_type(%{"trip_type" => "one_way"}), do: "One way"
  defp trip_summary_header_trip_type(%{"trip_type" => "round_trip"}), do: "Round trip"

  defp trip_summary_header_relevant_days(%{"relevant_days" => "weekday"}), do: "weekday"
  defp trip_summary_header_relevant_days(%{"relevant_days" => "sunday"}), do: "Sunday"
  defp trip_summary_header_relevant_days(%{"relevant_days" => "saturday"}), do: "Saturday"

  def trip_summary_details(%{"trip_type" => "one_way", "trips" => trips}, {origin_name, _}, {destination_name, _}) do
    [
      trip_summary_details_train_count(trips),
        " from ",
        origin_name,
        " to ",
        destination_name
    ]
  end
  def trip_summary_details(%{"trip_type" => "round_trip", "trips" => trips, "return_trips" => return_trips}, {origin_name, _}, {destination_name, _}) do
    [
      content_tag(:div, [
        trip_summary_details_train_count(trips),
          " from ",
          origin_name,
          " to ",
          destination_name
      ]),
      content_tag(:div, [
        trip_summary_details_train_count(return_trips),
          " from ",
          destination_name,
          " to ",
          origin_name
      ])
    ]
  end

  defp trip_summary_details_train_count([_trip]), do: "1 train"
  defp trip_summary_details_train_count(trips), do: [trips |> Enum.count() |> to_string(), " trains"]
end
