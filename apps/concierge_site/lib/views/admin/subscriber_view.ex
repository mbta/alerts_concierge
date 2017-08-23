defmodule ConciergeSite.Admin.SubscriberView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.{InformedEntity, Notification, Subscription, User}
  alias ConciergeSite.TimeHelper
  alias Calendar.Strftime

  @spec account_status(User.t) :: String.t
  def account_status(%User{encrypted_password: ""}), do: "Disabled"
  def account_status(%User{encrypted_password: nil}), do: "Disabled"
  def account_status(%User{}), do: "Active"

  def email_is_default?(user) do
    is_nil(user.phone_number)
  end

  def blackout_period(%User{do_not_disturb_start: nil, do_not_disturb_end: nil}), do: "N/A"
  def blackout_period(%User{do_not_disturb_start: dnd_start, do_not_disturb_end: dnd_end}) do
    [
      Strftime.strftime!(dnd_start, "%I:%M %p"),
      " to ",
      Strftime.strftime!(dnd_end, "%I:%M %p")
    ]
  end

  def vacation_period(%User{vacation_start: nil, vacation_end: nil}), do: "N/A"
  def vacation_period(%User{vacation_start: vacation_start, vacation_end: vacation_end}) do
    if DateTime.compare(vacation_end, DateTime.utc_now()) == :lt do
      "N/A"
    else
      [
        Strftime.strftime!(vacation_start, "%c"),
        " until ",
        Strftime.strftime!(vacation_end, "%c")
      ]
    end
  end

  @spec subscription_info(Subscription.t) :: Phoenix.HTML.Safe.t
  def subscription_info(%Subscription{origin: nil, destination: nil} = subscription) do
    [
      content_tag(:p, Subscription.type_string(subscription)),
      content_tag(:p, timeframe_string(subscription)),
      content_tag(:p, Subscription.relevant_days_string(subscription)),
      content_tag(:p, Subscription.severity_string(subscription))
    ]
  end
  def subscription_info(%Subscription{origin: origin, destination: destination} = subscription) do
    [
      content_tag(:p, "Origin: #{origin}"),
      content_tag(:p, "Destination: #{destination}"),
      content_tag(:p, Subscription.type_string(subscription)),
      content_tag(:p, timeframe_string(subscription)),
      content_tag(:p, Subscription.relevant_days_string(subscription)),
      content_tag(:p, Subscription.severity_string(subscription))
    ]
  end

  @spec entity_info(Subscription.t, map) :: iodata
  def entity_info(%Subscription{informed_entities: []}, _), do: "No Entities"
  def entity_info(%Subscription{informed_entities: informed_entities}, departure_time_map) do
    for informed_entity <- Enum.sort_by(informed_entities, &{InformedEntity.entity_type(&1), &1.facility_type, &1.stop, &1.trip, &1.direction_id}) do
      entity_item(informed_entity, departure_time_map)
    end
  end

  defp entity_item(%InformedEntity{route: route, facility_type: facility_type}, _) when is_binary(route) and is_atom(facility_type) and not is_nil(facility_type) do
    content_tag(:p, [
      facility_type |> Atom.to_string() |> String.capitalize() |> String.split("_"),
      " for ",
      route
    ])
  end
  defp entity_item(%InformedEntity{stop: stop, facility_type: facility_type}, _) when is_binary(stop) and is_atom(facility_type) and not is_nil(facility_type) do
    stop_string =
      case ServiceInfoCache.get_stop(stop) do
        {:ok, {stop_name, stop_id}} -> [stop_name, " (", stop_id, ")"]
        _ -> stop
      end

    content_tag(:p, [
      facility_type |> Atom.to_string() |> String.capitalize() |> String.split("_"),
      " at ",
      stop_string
    ])
  end
  defp entity_item(%InformedEntity{route: r, route_type: rt, stop: stop}, _) when is_binary(r) and is_number(rt) and is_binary(stop) do
    stop_string =
      case ServiceInfoCache.get_stop(stop) do
        {:ok, {stop_name, stop_id}} -> [stop_name, " (", stop_id, ")"]
        _ -> stop
      end

    content_tag(:p, [
      "Stop: ",
      stop_string
    ])
  end
  defp entity_item(%InformedEntity{trip: trip}, departure_time_map) when is_binary(trip) do
    content_tag(:p, [
      "Trip: ",
      trip,
      " departs at ",
      departure_time_map[trip] |> Calendar.Strftime.strftime!("%l:%M%P") |> String.trim()
    ])
  end
  defp entity_item(%InformedEntity{route: route, route_type: rt, direction_id: nil}, _) when is_binary(route) and is_number(rt) do
    route_string =
      case ServiceInfoCache.get_route(route) do
        {:ok, %{long_name: ""}} -> route
        {:ok, %{long_name: long_name}} -> [long_name, " (", route, ")"]
        _ -> route
      end

    content_tag(:p, [
      "Route: ",
      route_string
    ])
  end
  defp entity_item(%InformedEntity{route: route, route_type: rt, direction_id: direction_id}, _) when is_binary(route) and is_number(rt) do
    route_string =
      case ServiceInfoCache.get_route(route) do
        {:ok, %{long_name: ""}} -> route
        {:ok, %{long_name: long_name}} -> [long_name, " (", route, ")"]
        _ -> route
      end

    direction_string =
      case ServiceInfoCache.get_direction_name(route, direction_id) do
        {:ok, direction_name} -> direction_name
        _ -> ""
      end

    content_tag(:p, [
      "Route: ",
      route_string,
      " ",
      direction_string
    ])
  end
  defp entity_item(%InformedEntity{route_type: route_type}, _) when is_number(route_type) do
    content_tag(:p, [
      "Mode: ",
      InformedEntity.route_type_string(route_type)
    ])
  end
  defp entity_item(_, _), do: ""

  @doc """
  return iodata with timeframe of subscription.
  """
  @spec timeframe_string(Subscription.t) :: iodata
  def timeframe_string(%Subscription{start_time: start_time, end_time: end_time}) do
    [
      TimeHelper.format_time(start_time),
      " to ",
      TimeHelper.format_time(end_time)
    ]
  end

  def notification_info(%Notification{service_effect: service_effect, header: header, description: description}) do
    [
      content_tag(:p, service_effect),
      content_tag(:p, header),
      content_tag(:p, description)
    ]
  end

  def notification_type(%Notification{phone_number: nil}), do: content_tag(:p, "Email")
  def notification_type(%Notification{}), do: content_tag(:p, "SMS")

  def notification_timestamp(%Notification{send_after: send_after}), do: content_tag(:p, Strftime.strftime!(send_after, "%F %T"))
end
