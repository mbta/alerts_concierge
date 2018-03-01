defmodule ConciergeSite.CommuterRailSubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.SubscriptionHelper,
    only: [progress_link_class: 3, do_query_string_params: 2,
           do_hidden_form_inputs: 2, formatted_day: 1]
  import ConciergeSite.TimeHelper,
    only: [travel_time_options: 0]
  alias AlertProcessor.Model.TripInfo

  @type trip_type :: :one_way | :round_trip
  @type step :: :trip_type | :trip_info | :train | :preferences

  @disabled_progress_bar_links %{trip_info: [:trip_info, :train, :preferences],
    train: [:train, :preferences],
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
  constructs list of hidden pinputs to pass along relevant parameters to next or previous step
  via post request
  """
  @spec hidden_form_inputs(step, map | nil) :: [any]
  def hidden_form_inputs(step, params), do: do_hidden_form_inputs(params, params_for_step(step))

  @doc """
  returns list of parameters that should be present and passed along
  from the step given.
  """
  @spec params_for_step(step) :: [String.t]
  def params_for_step(:trip_type), do: ~w(trip_type)
  def params_for_step(:trip_info), do: ["origin", "destination", "relevant_days", "departure_start", "return_start", "route_id", "direction_id" | params_for_step(:trip_type)]
  def params_for_step(:train), do: ["trips", "return_trips" | params_for_step(:trip_info)]
  def params_for_step(:preferences), do: ["alert_priority_type" | params_for_step(:train)]
  def params_for_step(_), do: []

  @spec trip_option(:error | TripInfo.t, :depart | :return) :: Phoenix.HTML.safe
  def trip_option(:error, _), do: ""
  def trip_option(trip, trip_type) do
    content_tag :div, class: trip_option_classes(trip) do
      [
        trip_option_checkbox(trip, trip_type),
        content_tag :label, class: "trip-option-description", for: trip_id_string(trip) do
          trip_option_description(trip)
        end
      ]
    end
  end

  defp trip_option_classes(%{selected: true}), do: "trip-option closest-trip"
  defp trip_option_classes(_), do: "trip-option"

  defp trip_option_checkbox(trip, trip_type) do
    tag(:input,
        type: "checkbox",
        class: "trip-option-input",
        name: trip_option_name(trip_type),
        id: trip_id_string(trip),
        value: trip.trip_number,
        checked: trip.selected)
  end

  defp trip_option_name(:depart), do: "subscription[trips][]"
  defp trip_option_name(:return), do: "subscription[return_trips][]"

  defp trip_id_string(trip) do
    ["trip_", trip.trip_number]
  end

  defp trip_option_description(trip) do
    {origin_name, _, _, _} = trip.origin
    {destination_name, _, _, _} = trip.destination

    [
      "Train ",
      trip.trip_number,
      " | ",
      origin_name,
      " ",
      format_schedule_time(trip.departure_time),
      "  ",
      content_tag(:i, "", class: "fa fa-long-arrow-right trip-information-arrow"),
      "  ",
      destination_name,
      " ",
      format_schedule_time(trip.arrival_time)
    ]
  end

  defp format_schedule_time(time) do
    {:ok, time_string} = Calendar.Strftime.strftime(time, "%l:%M%P")
    String.trim(time_string)
  end


  def trip_summary_details(%{"trip_type" => "one_way", "trips" => trips, "relevant_days" => relevant_days}, {origin_name, _, _, _}, {destination_name, _, _, _}) do
    [
      trip_summary_details_day_train_count(relevant_days, trips),
        " from ",
        origin_name,
        " to ",
        destination_name
    ]
  end

  def trip_summary_details(%{"trip_type" => "round_trip", "trips" => trips, "return_trips" => return_trips, "relevant_days" => relevant_days}, {origin_name, _, _, _}, {destination_name, _, _, _}) do
    [
      content_tag(:div, [
        trip_summary_details_day_train_count(relevant_days, trips),
          " from ",
          origin_name,
          " to ",
          destination_name
      ]),
      content_tag(:div, [
        trip_summary_details_day_train_count(relevant_days, return_trips),
          " from ",
          destination_name,
          " to ",
          origin_name
      ])
    ]
  end

  defp trip_summary_details_day_train_count(day, [_trip]) do
    ["1 ", formatted_day(day),  " train"]
  end

  defp trip_summary_details_day_train_count(day, trips) do
    [trips |> Enum.count() |> to_string(), " ", formatted_day(day), " trains"]
  end

  defp trip_list_header(subscription) do
    case subscription.relevant_days do
      [:weekday] -> "Select Weekday Trains"
      [:sunday] -> "Select Sunday Trains"
      [:saturday] -> "Select Saturday Trains"
    end
  end
end
