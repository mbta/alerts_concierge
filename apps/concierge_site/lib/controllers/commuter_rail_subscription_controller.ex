defmodule ConciergeSite.CommuterRailSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{CommuterRailParams, Lines, TemporaryState}
  alias AlertProcessor.{Helpers.DateTimeHelper, ServiceInfoCache, Subscription.CommuterRailMapper}

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def info(conn, params, user, _claims) do
    subscription_params = Map.merge(params, %{user_id: user.id, route_type: 2})
    token = TemporaryState.encode(subscription_params)

    case ServiceInfoCache.get_commuter_rail_info do
      {:ok, stations} ->
        station_list_select_options =
          Lines.station_list_select_options(stations)

        render conn, "info.html",
          token: token,
          subscription_params: subscription_params,
          station_list_select_options: station_list_select_options
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> render("new.html", token: token, subscription_params: subscription_params)
    end
  end

  def train(conn, params, user, _claims) do
    subscription_params = Map.merge(
      params["subscription"], %{user_id: user.id, route_type: 2}
    )
    token = TemporaryState.encode(subscription_params)

    case CommuterRailParams.validate_info_params(subscription_params) do
      :ok ->
        case populate_trip_options(subscription_params) do
          {:error, message} ->
            handle_invalid_info_submission(conn, subscription_params, token, message)
          trips ->
            render conn, "train.html",
              token: token,
              subscription_params: subscription_params,
              trips: trips
        end
      {:error, message} ->
        handle_invalid_info_submission(conn, subscription_params, token, message)
    end
  end

  def preferences(conn, params, user, _claims) do
    subscription_params = Map.merge(
      params["subscription"], %{user_id: user.id, route_type: 2}
    )
    token = TemporaryState.encode(subscription_params)

    render conn, "preferences.html",
      token: token,
      subscription_params: subscription_params
  end

  defp populate_trip_options(%{"trip_type" => "one_way"} = subscription_params) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days, "departure_start" => ds} = subscription_params
    case get_trip_info(origin, destination, ds, relevant_days) do
      {:ok, trips, closest_trip} ->
        %{departure_trips: trips, closest_departure_trip: closest_trip}
      :error ->
        {:error, "Please correct the following errors to proceed: Please select a valid origin and destination combination."}
    end
  end
  defp populate_trip_options(%{"trip_type" => "round_trip"} = subscription_params) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days, "departure_start" => ds, "return_start" => rs} = subscription_params
    with {:ok, departure_trips, closest_departure_trip} <- get_trip_info(origin, destination, ds, relevant_days),
         {:ok, return_trips, closest_return_trip} <- get_trip_info(destination, origin, rs, relevant_days) do
      %{departure_trips: departure_trips, closest_departure_trip: closest_departure_trip, return_trips: return_trips, closest_return_trip: closest_return_trip}
    else
      _ -> {:error, "Please correct the following errors to proceed: Please select a valid origin and destination combination."}
    end
  end

  defp get_trip_info(origin, destination, timestamp, relevant_days) do
    case CommuterRailMapper.map_trip_options(origin, destination, String.to_existing_atom(relevant_days)) do
      {:ok, trips} ->
        departure_start = timestamp |> Time.from_iso8601!() |> DateTimeHelper.seconds_of_day()
        closest_trip = Enum.min_by(trips, &calculate_difference(&1, departure_start))
        {:ok, trips, closest_trip}
      _ ->
        :error
    end
  end

  defp calculate_difference(trip, departure_start) do
    departure_time = DateTimeHelper.seconds_of_day(trip.departure_time)
    abs(departure_start - departure_time)
  end

  defp handle_invalid_info_submission(conn, subscription_params, token, error_message) do
    case ServiceInfoCache.get_commuter_rail_info do
      {:ok, stations} ->
        station_list_select_options =
          Lines.station_list_select_options(stations)

        conn
        |> put_flash(:error, error_message)
        |> render(
          "info.html",
          token: token,
          subscription_params: subscription_params,
          station_list_select_options: station_list_select_options
        )
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> render("new.html", token: token, subscription_params: subscription_params)
    end
  end
end
