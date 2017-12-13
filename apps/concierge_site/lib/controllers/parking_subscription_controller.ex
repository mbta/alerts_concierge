defmodule ConciergeSite.ParkingSubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.Subscriptions.{ParkingParams}
  alias ConciergeSite.Helpers.MultiSelectHelper
  alias AlertProcessor.{ServiceInfoCache, Subscription.ParkingMapper,
    Subscription.Mapper, Model.Subscription, Model.User}

  def new(conn, _params, _user, _claims) do
    render_new_page(conn)
  end

  def create(conn, %{"subscription" => sub_params}, user, {:ok, claims}) do
    sub_params = Map.merge(sub_params, %{"user_id" => user.id})
    with :ok <- ParkingParams.validate_info_params(sub_params),
      {:ok, subscription_infos} <- ParkingMapper.map_subscriptions(sub_params),
      multi <- ParkingMapper.build_subscription_transaction(subscription_infos, user, Map.get(claims, "imp", user.id)),
      :ok <- Subscription.set_versioned_subscription(multi) do
        redirect(conn, to: subscription_path(conn, :index))
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> render_new_page()
      _ ->
        conn
        |> put_flash(:error, "there was an error saving the subscription. Please try again.")
        |> render_new_page()
    end
  end

  def edit(conn, %{"id" => id}, user, _) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do
        station_select_options = MultiSelectHelper.station_options(cr_stations, subway_stations)
        subscription = Subscription.one_for_user!(id, user.id, true)
        changeset = Subscription.update_changeset(subscription)

        render conn,
          "edit.html",
          subscription: subscription,
          changeset: changeset,
          station_select_options: station_select_options,
          selected_options: selected_options(subscription)
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error. Please try again.")
        |> redirect(to: subscription_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "subscription" => sub_params}, user, {:ok, claims}) do
    with subscription <- Subscription.one_for_user!(id, user.id, true),
      :ok <- ParkingParams.validate_info_params(sub_params),
      {:ok, subscription_infos} <- ParkingMapper.map_subscriptions(sub_params),
      multi <- Mapper.build_subscription_update_transaction(subscription, subscription_infos, Map.get(claims, "imp", user.id)),
      :ok <- Subscription.set_versioned_subscription(multi) do
        :ok = User.clear_holding_queue_for_user_id(user.id)
        redirect(conn, to: subscription_path(conn, :index))
    else
      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: parking_subscription_path(conn, :edit, id))
      _ ->
        conn
        |> put_flash(:error, "There was an error saving the subscription. Please try again.")
        |> redirect(to: parking_subscription_path(conn, :edit, id))
    end
  end

  defp render_new_page(conn) do
    with sub_params <- Map.get(conn.params, "subscription", %{}),
      {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes(),
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info() do

      station_select_options = MultiSelectHelper.station_options(cr_stations, subway_stations)

      selected_options = %{
        relevant_days: sub_params |> Map.get("relevant_days", []) |> Enum.reject(&empty_or_nil?/1),
        stations: sub_params |> Map.get("stops", []) |> Enum.map(&fetch_stop/1) |> Enum.reject(&empty_or_nil?/1)
      }

      render conn, :new,
        station_select_options: station_select_options,
        selected_options: selected_options
    else
      _error ->
        conn
        |> put_flash(:error, "There was an error fetching station data. Please try again.")
        |> redirect(to: subscription_path(conn, :new))
    end
  end

  defp selected_options(%Subscription{informed_entities: ies, relevant_days: relevant_days}) do
    ies
    |> Enum.reduce(
      %{relevant_days: MapSet.new, stations: MapSet.new},
      fn(ie, acc) ->
        if ie.stop do
          {:ok, stop} = ServiceInfoCache.get_stop(ie.stop)
          stations = MapSet.put(acc.stations, stop)
          Map.put(acc, :stations, stations)
        else
          acc
        end
      end)
      |> Map.put(:relevant_days, relevant_days |> Enum.reject(&empty_or_nil?/1) |> MapSet.new(&to_string/1))
      |> Map.new(fn({k, v}) -> {k, MapSet.to_list(v)} end)
  end

  defp empty_or_nil?(nil), do: true
  defp empty_or_nil?(""), do: true
  defp empty_or_nil?(_), do: false

  defp fetch_stop(stop_id) do
    {:ok, stop} = ServiceInfoCache.get_stop(stop_id)
    stop
  end
end
