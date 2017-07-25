defmodule ConciergeSite.AmenitySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{AmenitiesParams, Lines, TemporaryState}
  alias AlertProcessor.{Repo, ServiceInfoCache,
    Subscription.AmenitiesMapper, Model.Subscription, Model.User}

  def new(conn, _params, _user, _claims) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do

      station_select_options = station_options(cr_stations, subway_stations)

      render conn, :new,
        subscription_params: %{"stops" => []},
        station_list_select_options: station_select_options,
        selected_stations: []
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> redirect(to: subscription_path(conn, :new))
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

      render conn, :new,
        subscription_params: subscription_params,
        station_list_select_options: station_select_options,
        selected_stations: new_stations,
        token: token
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> redirect(to: subscription_path(conn, :new))
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
        render conn, :new,
          subscription_params: subscription_params,
          station_list_select_options: station_select_options,
          selected_stations: new_stations,
          token: token
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error. Please try again.")
        |> redirect(to: subscription_path(conn, :new))
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
    with :ok <- AmenitiesParams.validate_info_params(sub_params),
      {:ok, subscription_infos} <- AmenitiesMapper.map_subscriptions(sub_params),
      multi <- AmenitiesMapper.build_subscription_transaction(subscription_infos, user),
      {:ok, _} <- Repo.transaction(multi) do
        redirect(conn, to: subscription_path(conn, :index))
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render_new_page(sub_params)
      _ ->
        conn
        |> put_flash(:error, "there was an error saving the subscription. Please try again.")
        |> render_new_page(sub_params)
    end
  end

  def edit(conn, %{"id" => id}, user, _) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do
        station_select_options = station_options(cr_stations, subway_stations)
        subscription = Subscription.one_for_user!(id, user.id, true)
        changeset = Subscription.update_changeset(subscription)
        st = selected_trip_options(subscription, station_select_options)

        render conn,
          "edit.html",
          subscription: subscription,
          changeset: changeset,
          station_select_options: station_select_options,
          selected_trip_options: st
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error. Please try again.")
        |> redirect(to: subscription_path(conn, :index))
    end
  end

  defp selected_trip_options(%Subscription{informed_entities: ies}, options) do
    ies
    |> Enum.reduce(
      %{amenities: MapSet.new, routes: MapSet.new, stations: MapSet.new},
      fn(ie, acc) ->
        acc = case id_to_name(ie.stop, options) do
          {name, _id} ->
            Map.put(acc, :stations, MapSet.put(acc.stations, name))
          _ -> acc
        end

        acc = if is_nil(ie.facility_type) do
          acc
        else
          amenities = MapSet.put(acc.amenities, ie.facility_type)
          Map.put(acc, :amenities, amenities)
        end

        if is_nil(ie.route) do
          acc
        else
          routes = MapSet.put(
            acc.amenities,
            String.downcase(ie.route)
          )
          Map.put(acc, :routes, routes)
        end
      end)
      |> Enum.reduce(%{}, fn({k, v}, acc) ->
        Map.put(acc, k, MapSet.to_list(v))
      end)
  end

  def update(conn, %{"id" => id, "subscription" => sub_params}, user, _) do
    with subscription <- Subscription.one_for_user!(id, user.id, true),
      :ok <- AmenitiesParams.validate_info_params(sub_params),
      {:ok, subscription_infos} <- AmenitiesMapper.map_subscriptions(sub_params),
      multi <- AmenitiesMapper.build_subscription_update_transaction(subscription, subscription_infos),
      {:ok, _subscription} <- Repo.transaction(multi) do
        :ok = User.clear_holding_queue_for_user_id(user.id)
        redirect(conn, to: subscription_path(conn, :index))
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: amenity_subscription_path(conn, :edit, id))
      _ ->
        conn
        |> put_flash(:error, "There was an error saving the subscription. Please try again.")
        |> redirect(to: amenity_subscription_path(conn, :edit, id))
    end
  end

  defp render_new_page(conn, sub_params) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do

      station_select_options = station_options(cr_stations, subway_stations)

      render conn, :new,
        subscription_params: sub_params,
        station_list_select_options: station_select_options,
        selected_stations: String.split(sub_params["stops"], ",", trim: true)
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> redirect(to: subscription_path(conn, :new))
    end
  end
end
