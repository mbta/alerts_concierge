defmodule ConciergeSite.FerrySubscriptionView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.Trip
  import ConciergeSite.SubscriptionHelper,
    only: [progress_link_class: 3, do_query_string_params: 2, do_hidden_form_inputs: 2]
  import ConciergeSite.TimeHelper,
    only: [travel_time_options: 0]

  @type step :: :trip_type | :trip_info | :ferry | :preferences

  @disabled_progress_bar_links %{trip_info: [:trip_info, :ferry, :preferences],
  ferry: [:ferry, :preferences],
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
  def params_for_step(:trip_info), do: ["origin", "destination", "relevant_days", "departure_start", "return_start" | params_for_step(:trip_type)]
  def params_for_step(:ferry), do:  ["trips", "return_trips" | params_for_step(:trip_info)]
  def params_for_step(:preferences), do: ["alert_priority_type" | params_for_step(:ferry)]
  def params_for_step(_), do: []

  @doc """
  Provide description text for Trip Info page based on which trip type selected
  """
  @spec trip_info_description(any) :: String.t
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

  @spec trip_option(Trip.t, :depart | :return) :: Phoenix.HTML.safe
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
    {origin_name, _} = trip.origin
    {destination_name, _} = trip.destination

    [
      format_schedule_time(trip.departure_time),
      " from ",
      origin_name,
      ", arrives at ",
      destination_name,
      " at ",
      format_schedule_time(trip.arrival_time)
    ]
  end

  defp format_schedule_time(time) do
    {:ok, time_string} = Calendar.Strftime.strftime(time, "%l:%M%P")
    String.trim(time_string)
  end
end
