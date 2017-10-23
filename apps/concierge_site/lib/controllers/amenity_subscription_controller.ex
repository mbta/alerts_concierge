defmodule ConciergeSite.AmenitySubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{AmenitiesParams}
  alias ConciergeSite.Helpers.MultiSelectHelper
  alias AlertProcessor.{ServiceInfoCache,
    Subscription.AmenitiesMapper, Model.Subscription, Model.User}

  def new(conn, _params, _user, _claims) do
    render_new_page(conn, %{"stops" => []}, [])
  end

  def create(conn, %{"subscription" => sub_params}, user, {:ok, claims}) do
    sub_params = Map.merge(sub_params, %{"user_id" => user.id})
    with :ok <- AmenitiesParams.validate_info_params(sub_params),
      {:ok, subscription_infos} <- AmenitiesMapper.map_subscriptions(sub_params),
      multi <- AmenitiesMapper.build_subscription_transaction(subscription_infos, user, Map.get(claims, "imp", user.id)),
      :ok <- Subscription.set_versioned_subscription(multi) do
        redirect(conn, to: subscription_path(conn, :index))
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render_new_page(sub_params, String.split(sub_params["stops"], ",", trim: true))
      _ ->
        conn
        |> put_flash(:error, "there was an error saving the subscription. Please try again.")
        |> render_new_page(sub_params, String.split(sub_params["stops"], ",", trim: true))
    end
  end

  def edit(conn, %{"id" => id}, user, _) do
    render_edit_page(conn, id, user, %{}, nil)
  end

  def update(conn, %{"id" => id, "subscription" => sub_params}, user, {:ok, claims}) do
    with subscription <- Subscription.one_for_user!(id, user.id, true),
      :ok <- AmenitiesParams.validate_info_params(sub_params),
      {:ok, subscription_infos} <- AmenitiesMapper.map_subscriptions(sub_params),
      multi <- AmenitiesMapper.build_subscription_update_transaction(subscription, subscription_infos, Map.get(claims, "imp", user.id)),
      :ok <- Subscription.set_versioned_subscription(multi) do
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
        station_select_options = MultiSelectHelper.station_options(cr_stations, subway_stations)
        subscription = Subscription.one_for_user!(id, user.id, true)
        changeset = Subscription.update_changeset(subscription, sub_params)
        st = set_station_options(operation, sub_params, subscription)

        render conn,
          "edit.html",
          subscription: subscription,
          changeset: changeset,
          station_select_options: station_select_options,
          selected_station_options: st
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error. Please try again.")
        |> redirect(to: subscription_path(conn, :index))
    end
  end

  defp render_new_page(conn, sub_params, selected_stations) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do

      station_select_options = MultiSelectHelper.station_options(cr_stations, subway_stations)

      subscription_params = Map.put(sub_params, "stops", selected_stations)

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

  defp set_station_options(operation, sub_params, subscription) do
    case operation do
      :add ->
        subscription
        |> selected_station_options()
        |> MultiSelectHelper.replace_stops(sub_params)
        |> MultiSelectHelper.add_station_selection(sub_params)
      :remove ->
        subscription
        |> selected_station_options()
        |> MultiSelectHelper.replace_stops(sub_params)
        |> MultiSelectHelper.remove_station_selection(sub_params)
      nil ->
        selected_station_options(subscription)
    end
  end

  defp selected_station_options(%Subscription{informed_entities: ies}) do
    ies
    |> Enum.reduce(
      %{amenities: MapSet.new, routes: MapSet.new, stations: MapSet.new},
      fn(ie, acc) ->

        acc =
          if ie.stop do
            {:ok, stop} = ServiceInfoCache.get_stop(ie.stop)
            stations = MapSet.put(acc.stations, stop)
            Map.put(acc, :stations, stations)
          else
            acc
          end

        acc =
          if is_nil(ie.facility_type) do
            acc
          else
            amenities = MapSet.put(acc.amenities, ie.facility_type)
            Map.put(acc, :amenities, amenities)
          end

        if is_nil(ie.route) do
          acc
        else
          routes = MapSet.put(acc.routes, String.downcase(ie.route))
          Map.put(acc, :routes, routes)
        end
      end)
      |> Enum.reduce(%{}, fn({k, v}, acc) ->
        Map.put(acc, k, MapSet.to_list(v))
      end)
  end
end
