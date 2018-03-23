defmodule AlertProcessor.Model.Subscription.Params do
  alias AlertProcessor.{Model.Subscription, ServiceInfoCache}

  defstruct [
    return_start: nil,
    return_end: nil,
    departure_start: nil,
    departure_end: nil,
    is_return_trip?: false,
    origin: nil,
    destination: nil,
    route: nil,
    direction_id: nil,
    relevant_days: [],
  ]

  def create_subscriptions(%{"return_start" => nil, "return_end" => nil} = params) do
    [do_create_subscription(params)]
  end
  def create_subscriptions(%{"origin" => origin, "destination" => destination} = params) do
    import Map, only: [put: 3]
    return_params =
      params
      |> put("destination", origin)
      |> put("origin", destination)
      |> put("departure_start", params["return_start"])
      |> put("departure_end", params["return_end"])
      |> put("direction", flip_direction(params["direction"]))
    IO.inspect(params, label: "WTF_man")
    [do_create_subscription(params), do_create_subscription(return_params)]
  end
  def create_subscriptions(_), do: :error

  defp flip_direction(0), do: 1
  defp flip_direction(1), do: 0
  defp flip_direction(_), do: nil

  defp do_create_subscription(params) do
    subscription = %Subscription{
      start_time: params["departure_start"],
      end_time: params["departure_end"],
      relevant_days: relevant_days_to_atoms(params),
      origin: params["origin"],
      destination: params["destination"],
      route: params["route"],
      direction_id: params["direction"]
    }
    case {get_latlong_from_stop(params["origin"]), get_latlong_from_stop(params["destination"])} do
      {nil, nil} -> subscription
      {{origin_lat, origin_long}, {destination_lat, destination_long}} ->
        %{subscription | origin_lat: origin_lat, origin_long: origin_long, destination_lat: destination_lat,
                         destination_long: destination_long}
    end
  end

  defp get_latlong_from_stop(nil), do: nil
  defp get_latlong_from_stop(stop_id) do
    case ServiceInfoCache.get_stop(stop_id) do
      {:ok, stop} -> elem(stop, 2)
      _ -> nil
    end
  end


  # def from_json(%{"return_start" => nil, "return_end" => nil} = params) do
  #   [struct_from_json(params)]
  # end
  # def from_json(%{} = params) do
  #   forward_trip = struct_from_json(params)
  #   reverse_trip = struct_from_json(params) |> to_return_trip
  #   [forward_trip, reverse_trip]
  # end

  # def to_subscription_struct(%__MODULE__{} = params) do
  #   {origin_lat, origin_long} = get_latlong_from_stop(params.origin)
  #   {destination_lat, destination_long} = get_latlong_from_stop(params.destination)
  #   %Subscription{
  #     start_time: params.departure_start,
  #     end_time: params.departure_end,
  #     relevant_days: params.relevant_days,
  #     origin: params.origin,
  #     destination: params.destination,
  #     route: params.route,
  #     direction_id: params.direction_id,
  #     origin_lat: origin_lat,
  #     origin_long: origin_long,
  #     destination_lat: destination_lat,
  #     destination_long: destination_long,
  #   }
  # end

  # defp get_latlong_from_stop(nil) do
  #   {nil, nil}
  # end
  # defp get_latlong_from_stop(stop_id) do
  #   case ServiceInfoCache.get_stop(stop_id) do
  #     {:ok, stop} ->
  #       {_, _} = elem(stop, 2)
  #     _ ->
  #       {nil, nil}
  #   end
  # end

  # defp struct_from_json(params) do
  #   %__MODULE__{
  #     return_start:     params["return_start"],
  #     return_end:       params["return_end"],
  #     departure_start:  params["departure_start"],
  #     departure_end:    params["departure_end"],
  #     origin:           params["origin"],
  #     destination:      params["destination"],
  #     route:            params["route"],
  #     direction_id:     params["direction"],
  #     relevant_days: relevant_days_to_atoms(params),
  #   }
  # end

  # defp to_return_trip(%__MODULE__{} = params) do
  #   %{
  #     params |
  #     is_return_trip?: true,
  #     origin: params.destination,
  #     destination: params.origin,
  #     direction_id: flip_direction_id(params),
  #     # return_start: params.return_start,
  #     # return_end: params.return_end,
  #     departure_start: params.return_start,
  #     departure_end: params.return_end,
  #   }
  # end

  def relevant_days_to_atoms(params) do
    params
    |> Map.get("relevant_days", [])
    |> Enum.map(&String.to_existing_atom/1)
  end


  # defp flip_direction_id(0), do: 1
  # defp flip_direction_id(1), do: 0
  # defp flip_direction_id(_), do: nil

end