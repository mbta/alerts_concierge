defmodule ConciergeSite.BusSubscriptionView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.Subscription
  import ConciergeSite.SubscriptionHelper,
    only: [atomize_keys: 1, joined_day_list: 1, progress_link_class: 3, do_query_string_params: 2]
  import ConciergeSite.TimeHelper,
    only: [travel_time_options: 0, time_option_local_strftime: 1,
           format_time: 1]
  import ConciergeSite.SubscriptionView,
    only: [parse_route: 1]
  alias ConciergeSite.Subscriptions.SubscriptionParams

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
    "route", "departure_start", "departure_end", "return_start", "return_end",
    "weekday", "saturday", "sunday" | params_for_step(:trip_type)
  ]
  def params_for_step(:preferences), do: ["alert_priority_type" | params_for_step(:trip_info)]
  def params_for_step(_), do: []

  def selected_relevant_days(params) do
    params
    |> SubscriptionParams.relevant_days_from_booleans()
    |> Enum.map(&String.to_existing_atom/1)
  end

  @doc """
  Returns a route's full name, example: "Route 57A Inbound"
  """
  @spec route_name(Subscription.t) :: iodata
  def route_name(subscription) do
    route = parse_route(subscription)
    direction = direction_name(subscription)
    ["Route ", route.long_name, " ", direction]
  end

  defp direction_name(subscription) do
    subscription.informed_entities
    |> Enum.filter_map(&(!is_nil(&1.direction_id)), &(&1.direction_id))
    |> List.first()
    |> Integer.to_string()
    |> named_direction()
  end

  @doc """
  Returns a summary of a subscription's associated trip days, times, and stops
  """
  @spec trip_summary_title(map) :: iodata
  def trip_summary_title(%{"trip_type" => "one_way"} = params) do
    ["One way ",
     joined_day_list(params),
     " travel on the ",
     name_from_route(params["route"]),
    " bus:"]
  end

  def trip_summary_title(%{"trip_type" => "round_trip"} = params) do
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

  def trip_summary_routes(%{"trip_type" => "round_trip"} = params) do
    [
      departure_format(params),
      return_format(params)
    ]
  end

  def trip_summary_routes(%{"trip_type" => "one_way"} = params) do
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
