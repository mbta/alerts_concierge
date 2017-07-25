defmodule ConciergeSite.AmenitySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{AmenitiesParams, Lines}
  alias AlertProcessor.{Repo, ServiceInfoCache,
    Subscription.AmenitiesMapper, Model.Subscription, Model.User}

  def new(conn, _params, _user, _claims) do
    render_new_page(conn, %{"stops" => []}, [], :new)
  end

  def add_station(conn, %{"subscription" => %{"id" => id} = sub_params}, user, _claims) do
    render_edit_page(conn, id, user, sub_params, :add)
  end
  def add_station(conn, %{"subscription" => sub_params}, _user, _claims) do
    render_new_page(conn, sub_params, [], :add)
  end

  def remove_station(conn, %{"station" => station, "subscription" => %{"id" => id} = sub_params}, user, _claims) do
    sub_params = Map.merge(sub_params, %{"station" => station})
    render_edit_page(conn, id, user, sub_params, :remove)
  end
  def remove_station(conn, %{"station" => station, "subscription" => sub_params}, _user, _claims) do
    new_stations = remove_station_from_list(sub_params, station)
    render_new_page(conn, sub_params, new_stations, :remove)
  end

  def create(conn, %{"subscription" => sub_params}, user, _claims) do
    sub_params = Map.merge(sub_params, %{"user_id" => user.id})
    with :ok <- AmenitiesParams.validate_info_params(sub_params),
      {:ok, subscription_infos} <- AmenitiesMapper.map_subscriptions(sub_params),
      multi <- AmenitiesMapper.build_subscription_transaction(subscription_infos, user),
      {:ok, _} <- Repo.transaction(multi) do
        redirect(conn, to: subscription_path(conn, :index))
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render_new_page(sub_params, String.split(sub_params["stops"], ",", trim: true), :create)
      _ ->
        conn
        |> put_flash(:error, "there was an error saving the subscription. Please try again.")
        |> render_new_page(sub_params, String.split(sub_params["stops"], ",", trim: true), :create)
    end
  end

  def edit(conn, %{"id" => id}, user, _) do
    render_edit_page(conn, id, user, %{}, nil)
  end

  def update(conn, %{"id" => id, "subscription" => sub_params}, user, _) do
    with subscription <- Subscription.one_for_user!(id, user.id, true),
      :ok <- AmenitiesParams.validate_info_params(sub_params),
      {:ok, subscription_infos} <- AmenitiesMapper.map_subscriptions(sub_params),
      multi <- AmenitiesMapper.build_subscription_update_transaction(subscription, subscription_infos),
      {:ok, _} <- Repo.transaction(multi) do
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

  defp render_edit_page(conn, id, user, sub_params, operation) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do
        station_select_options = station_options(cr_stations, subway_stations)
        subscription = Subscription.one_for_user!(id, user.id, true)
        changeset = Subscription.update_changeset(subscription, sub_params)
        st = case operation do
          :add ->
            subscription
            |> selected_trip_options(station_select_options)
            |> replace_stops(sub_params)
            |> add_station_selection(sub_params, station_select_options)
          :remove ->
            subscription
            |> selected_trip_options(station_select_options)
            |> replace_stops(sub_params)
            |> remove_station_selection(sub_params, station_select_options)
          nil ->
            selected_trip_options(subscription, station_select_options)
        end

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

  defp render_new_page(conn, sub_params, selected_stations, type) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do

      station_select_options = station_options(cr_stations, subway_stations)

      selected_stations = if type == :add do
          add_station_to_list(sub_params, station_select_options)
        else
          selected_stations
        end

      subscription_params =
        sub_params
        |> Map.merge(%{
          "route_type" => 4,
          "stops" => selected_stations
        })
        |> Map.drop(["station"])

      render conn, :new,
        subscription_params: subscription_params,
        station_list_select_options: station_select_options,
        selected_stations: selected_stations
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> redirect(to: subscription_path(conn, :new))
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

  defp replace_stops(trip_options, params) do
    stations = String.split(params["stops"], ",", trim: true)
    put_in(trip_options, [:stations], stations)
  end

  defp add_station_selection(trip_options, params, options) do
    stations = add_station_to_list(params, options)
    put_in(trip_options, [:stations], stations)
  end

  defp remove_station_selection(trip_options, params, options) do
    stations = remove_station_from_list(params, params["station"])
    put_in(trip_options, [:stations], stations)
  end

  defp add_station_to_list(sub_params, options) do
    stations = String.split(sub_params["stops"], ",", trim: true)

    {station_name, _station_id} = sub_params["station"]
    |> id_to_name(options)

    stations
    |> Kernel.++([station_name])
    |> Enum.uniq()
  end

  defp remove_station_from_list(sub_params, station) do
    stations = String.split(sub_params["stops"], ",", trim: true)
    stations -- [station]
  end

  defp id_to_name(station, options) do
    options
    |> Enum.map(fn({_route, stops}) -> stops end)
    |> List.flatten
    |> Enum.find(fn({_name, id}) -> id == station end)
  end

  defp station_options(cr_stations, subway_stations) do
    subway_stations
      |> Kernel.++(cr_stations)
      |> Lines.station_list_select_options()
  end
end
