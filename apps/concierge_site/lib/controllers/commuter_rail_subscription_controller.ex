defmodule ConciergeSite.CommuterRailSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.TemporaryState
  alias ConciergeSite.Subscriptions.Lines
  alias AlertProcessor.{ServiceInfoCache, Subscription.CommuterRailMapper}

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

    %{"subscription" => %{"relevant_days" => relevant_days, "origin" => origin, "destination" => destination, "trip_type" => trip_type}} = params

    trips = populate_trip_options(origin, destination, relevant_days, trip_type)

    render conn, "train.html",
      token: token,
      subscription_params: subscription_params,
      trips: trips
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

  defp populate_trip_options(origin, destination, relevant_days, "one_way") do
    %{
      departure_trips: CommuterRailMapper.map_trip_options(origin, destination, String.to_existing_atom(relevant_days))
    }
  end
  defp populate_trip_options(origin, destination, relevant_days, "round_trip") do
    %{
      departure_trips: CommuterRailMapper.map_trip_options(origin, destination, String.to_existing_atom(relevant_days)),
      return_trips: CommuterRailMapper.map_trip_options(destination, origin, String.to_existing_atom(relevant_days))
    }
  end
end
