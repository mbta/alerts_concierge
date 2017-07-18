defmodule ConciergeSite.AmenitySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Repo, ServiceInfoCache, Subscription}
  alias Subscription.AmenitiesMapper
  alias ConciergeSite.Subscriptions.{Lines, TemporaryState}

  def new(conn, _params, _user, _claims) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do

      station_select_options = station_options(cr_stations, subway_stations)

      render conn, "new.html",
        subscription_params: %{"stops" => []},
        station_list_select_options: station_select_options,
        selected_stations: []
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> redirect(to: "/subscriptions/new")
    end
  end

  def add_station(conn, %{"subscription" => sub_params}, user, _claims) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do

      station_select_options = station_options(cr_stations, subway_stations)

      new_stations = add_station_to_list(sub_params, station_select_options)
      subscription_params = sub_params
        |> Map.merge(%{
          "user_id" => user.id,
          "route_type" => 4,
          "stops" => new_stations
        })
        |> Map.drop(["station"])

      token = TemporaryState.encode(subscription_params)

      render conn, "new.html",
        subscription_params: subscription_params,
        station_list_select_options: station_select_options,
        selected_stations: new_stations,
        token: token
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> redirect(to: "/subscriptions/new")
    end
  end

  defp add_station_to_list(sub_params, options) do
    stations = String.split(sub_params["stops"], ",", trim: true)

    {station_name, _station_id} = sub_params["station"]
    |> id_to_name(options)

    stations
    |> Kernel.++([station_name])
    |> Enum.uniq()
  end

  defp id_to_name(station, options) do
    options
    |> Enum.map(fn({_route, stops}) -> stops end)
    |> List.flatten
    |> Enum.find(fn({_name, id}) -> id == station end)
  end

  def remove_station(conn, %{"station" => station} = params, user, _claims) do
    sub_params = params["subscription"]
    new_stations = remove_station_from_list(sub_params, station)
    subscription_params = params["subscription"]
      |> Map.merge(%{"user_id" => user.id, "route_type" => 4, "stops" => new_stations})
      |> Map.drop(["station"])

    token = TemporaryState.encode(subscription_params)
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do
        station_select_options = station_options(cr_stations, subway_stations)
        render conn, "new.html",
          subscription_params: subscription_params,
          station_list_select_options: station_select_options,
          selected_stations: new_stations,
          token: token
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error. Please try again.")
        |> redirect(to: "/subscriptions/new")
    end
  end

  defp remove_station_from_list(sub_params, station) do
    stations = String.split(sub_params["stops"], ",", trim: true)
    stations -- [station]
  end

  defp station_options(cr_stations, subway_stations) do
    subway_stations
      |> Kernel.++(cr_stations)
      |> Lines.station_list_select_options()
  end

  def create(conn, %{"subscription" => sub_params}, user, _claims) do
    with {:ok, subscription_infos} <- AmenitiesMapper.map_subscriptions(sub_params),
      multi <- AmenitiesMapper.build_subscription_transaction(subscription_infos, user),
      {:ok, _} <- Repo.transaction(multi) do
        redirect(conn, to: subscription_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "There was an error saving the subscription. Please try again.")
        |> redirect(to: amenity_subscription_path(conn, :new))
    end
  end

  def edit(conn, %{"id" => _id}, _user, _) do
    conn
    |> render(:edit)
  end
end
