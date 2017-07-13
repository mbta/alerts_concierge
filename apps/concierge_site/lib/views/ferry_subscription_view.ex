defmodule ConciergeSite.FerrySubscriptionView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.Trip
  import ConciergeSite.SubscriptionHelper,
    only: [atomize_keys: 1, progress_link_class: 3, query_string_params: 1]
  import ConciergeSite.TimeHelper,
    only: [travel_time_options: 0]

  @type steps :: :trip_type | :trip_info | :ferry | :preferences

  @disabled_progress_bar_links %{trip_info: [:trip_info, :ferry, :preferences],
  ferry: [:ferry, :preferences],
  preferences: [:preferences]}

  defdelegate progress_step_classes(page, step), to: ConciergeSite.SubscriptionHelper

  def progress_link_class(page, step), do: progress_link_class(page, step, @disabled_progress_bar_links)

  @doc """
  constructs keyword list of parameters to pass along relevant parameters to next or previous step
  via get request
  """
  @spec query_string_params(steps, map | nil) :: keyword(String.t)
  def query_string_params(_step, nil), do: []
  def query_string_params(step, params), do: query_string_params(Map.take(params, params_for_step(step)))

  @doc """
  returns list of parameters that should be present and passed along
  from the step given.
  """
  @spec params_for_step(steps) :: [String.t]
  def params_for_step(:trip_type), do: ~w(trip_type)
  def params_for_step(:trip_info), do: params_for_step(:trip_type) ++ ~w(origin destination relevant_days departure_start return_start)
  def params_for_step(:ferry), do:  params_for_step(:trip_info) ++ ~w(trips return_trips)
  def params_for_step(:preferences), do: params_for_step(:ferry) ++ ~w(alert_priority_type)
  def params_for_step(_), do: []

  @doc """
  constructs list of hidden pinputs to pass along relevant parameters to next or previous step
  via post request
  """
  @spec hidden_params(steps, map) :: [any]
  def hidden_params(step, params) do
    relevant_params = Map.take(params, params_for_step(step))

    for param <- atomize_keys(relevant_params) do
      hidden_param(param)
    end
  end

  defp hidden_param({param_name, param_value}) when param_name == :trips or param_name == :return_trips do
    for trip_number <- param_value do
      tag(:input, type: "hidden", name: "subscription[#{param_name}][]", value: trip_number)
    end
  end
  defp hidden_param({param_name, param_value}) do
    tag(:input, type: "hidden", name: "subscription[#{param_name}]", value: param_value)
  end

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
