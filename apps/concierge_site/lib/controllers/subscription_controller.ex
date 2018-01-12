defmodule ConciergeSite.SubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  alias AlertProcessor.{Model.Subscription, Model.User, Subscription.DisplayInfo}
  alias AlertProcessor.Repo
  alias ConciergeSite.TimeHelper

  def index(conn, _params, user, _claims) do
    case Subscription.for_user(user) do
      [] ->
        redirect(conn, to: subscription_path(conn, :new))
      subscriptions ->
        {:ok, station_display_names} = DisplayInfo.station_names_for_subscriptions(subscriptions)
        {:ok, departure_time_map} = DisplayInfo.departure_times_for_subscriptions(subscriptions)

        dnd_overlap =
          Enum.any?(subscriptions, fn(subscription) ->
            TimeHelper.subscription_during_do_not_disturb?(subscription, user)
          end)

        render conn, "index.html",
          dnd_overlap: dnd_overlap,
          subscriptions: subscriptions,
          station_display_names: station_display_names,
          departure_time_map: departure_time_map,
          vacation_start: user.vacation_start,
          vacation_end: user.vacation_end
    end
  end

  def new(conn, _params, _user, _claims) do
    render conn, "new.html"
  end

  def edit(conn, _params, _user, _claims) do
    render conn, "edit.html"
  end

  def confirm_delete(conn, %{"id" => id}, user, _claims) do
    subscription =
      id
      |> Subscription.one_for_user!(user.id)
      |> Repo.preload(:informed_entities)
    {:ok, station_display_names} = DisplayInfo.station_names_for_subscriptions([subscription])
    {:ok, departure_time_map} = DisplayInfo.departure_times_for_subscriptions([subscription])
    render conn, "confirm_delete.html", subscription: subscription, station_display_names: station_display_names, departure_time_map: departure_time_map
  end

  def delete(conn, %{"id" => id}, user, {:ok, claims}) do
    subscription = Subscription.one_for_user!(id, user.id)
    case Subscription.delete_subscription(subscription, Map.get(claims, "imp", user.id)) do
      {:ok, _} ->
        :ok = User.clear_holding_queue_for_user_id(user.id)
        conn
        |> put_flash(:info, "Alert deleted")
        |> redirect(to: subscription_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, "Alert could not be deleted. Please try again.")
        |> render("confirm_delete.html", subscription: subscription)
    end
  end
end
