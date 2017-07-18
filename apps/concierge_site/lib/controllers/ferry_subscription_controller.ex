defmodule ConciergeSite.FerrySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{FerryParams, Lines, TemporaryState}
  alias AlertProcessor.{ServiceInfoCache, Subscription.FerryMapper}

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def info(conn, params, user, _claims) do
    subscription_params = Map.merge(params, %{"user_id" => user.id, "route_type" => 4})
    token = TemporaryState.encode(subscription_params)

    case ServiceInfoCache.get_ferry_info() do
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

  def ferry(conn, params, user, _claims) do
    subscription_params = Map.merge(
      params["subscription"], %{"user_id" => user.id, "route_type" => 4}
    )
    token = TemporaryState.encode(subscription_params)

    with :ok <- FerryParams.validate_info_params(subscription_params),
      {:ok, trips} <- FerryMapper.populate_trip_options(subscription_params) do
      render conn, "ferry.html",
        token: token,
        subscription_params: subscription_params,
        trips: trips
    else
      {:error, message} ->
        handle_invalid_info_submission(conn, subscription_params, token, message)
    end
  end

  def preferences(conn, params, user, _claims) do
    subscription_params = Map.merge(
      params["subscription"], %{"user_id" => user.id, "route_type" => 4}
    )
    token = TemporaryState.encode(subscription_params)

    with :ok <- FerryParams.validate_trip_params(subscription_params),
         {:ok, origin} <- ServiceInfoCache.get_stop(subscription_params["origin"]),
         {:ok, destination} <- ServiceInfoCache.get_stop(subscription_params["destination"]) do
      render conn, "preferences.html",
        token: token,
        subscription_params: subscription_params,
        origin: origin,
        destination: destination
    else
      {:error, message} ->
        handle_invalid_trip_submission(conn, subscription_params, token, message)
      _ ->
        handle_invalid_trip_submission(conn, subscription_params, token, "Something went wrong, please try again.")
    end
  end

  defp handle_invalid_info_submission(conn, subscription_params, token, error_message) do
    case ServiceInfoCache.get_ferry_info() do
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

  def handle_invalid_trip_submission(conn, subscription_params, token, error_message) do
    {:ok, trips} = FerryMapper.populate_trip_options(subscription_params)

    conn
    |> put_flash(:error, error_message)
    |> render(
      "ferry.html",
      token: token,
      subscription_params: Map.drop(subscription_params, ["trips", "return_trips"]),
      trips: trips
    )
  end
end
