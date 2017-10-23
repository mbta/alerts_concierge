defmodule ConciergeSite.BusSubscriptionView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.{InformedEntity, Route, Subscription}
  import ConciergeSite.SubscriptionHelper,
    only: [atomize_keys: 1, joined_day_list: 1, progress_link_class: 3,
           do_query_string_params: 2, selected_relevant_days: 1]
  import ConciergeSite.TimeHelper,
    only: [travel_time_options: 0, time_option_local_strftime: 1,
           format_time_string: 1]
  import ConciergeSite.SubscriptionView,
    only: [parse_route: 1]

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
    "routes", "departure_start", "departure_end", "return_start", "return_end",
    "weekday", "saturday", "sunday" | params_for_step(:trip_type)
  ]
  def params_for_step(:preferences), do: ["alert_priority_type" | params_for_step(:trip_info)]
  def params_for_step(_), do: []

  @doc """
  Returns a route's full name, example: "Route 57A Inbound"
  """
  @spec route_name(Subscription.t) :: iodata
  def route_name(subscription) do
    route_entity_count =  Enum.count(subscription.informed_entities, &InformedEntity.entity_type(&1) == :route && &1.direction_id != nil)
    if route_entity_count > 1 do
      [to_string(route_entity_count), " Bus Routes"]
    else
      route = parse_route(subscription)
      direction = direction_name(subscription)
      ["Route ", Route.name(route), " ", direction]
    end
  end

  defp direction_name(subscription) do
    subscription.informed_entities
    |> Enum.filter_map(&(!is_nil(&1.direction_id)), &(&1.direction_id))
    |> List.first()
    |> Integer.to_string()
    |> named_direction()
  end

  defp direction_from_route([route]) do
    route
    |> String.split(" - ")
    |> List.last
    |> named_direction()
  end

  def trip_summary_routes(%{"trip_type" => "round_trip"} = params, routes) do
    [
      departure_format(params, routes),
      return_format(params, routes)
    ]
  end
  def trip_summary_routes(%{"trip_type" => "one_way"} = params, routes) do
    [departure_format(params, routes)]
  end

  defp departure_format(params, [route]) do
    ["Route ",
     Route.name(route),
     " ",
     direction_from_route(params["routes"]),
     ", ",
     joined_day_list(params),
     " ",
     format_time_string(params["departure_start"]),
     " - ",
     format_time_string(params["departure_end"])]
  end
  defp departure_format(params, routes) do
    [to_string(Enum.count(routes)),
    " Bus Routes, ",
    joined_day_list(params),
    " ",
    format_time_string(params["departure_start"]),
    " - ",
    format_time_string(params["departure_end"])]
  end

  defp return_format(params, [route]) do
    direction = direction_from_route(params["routes"])
    ["Route ",
     Route.name(route),
     " ",
     reverse_direction(direction),
     ", ",
     joined_day_list(params),
     " ",
     format_time_string(params["return_start"]),
     " - ",
     format_time_string(params["return_end"])]
  end
  defp return_format(params, routes) do
    [to_string(Enum.count(routes)),
    " Bus Routes, ",
    joined_day_list(params),
    " ",
    format_time_string(params["return_start"]),
    " - ",
    format_time_string(params["return_end"])]
  end

  defp reverse_direction("inbound"), do: "outbound"
  defp reverse_direction("outbound"), do: "inbound"

  defp named_direction("0"), do: "outbound"
  defp named_direction("1"), do: "inbound"
end
