defmodule ConciergeSite.SubscriptionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  alias AlertProcessor.{Model.Subscription, Model.User, Subscription.DisplayInfo}
  alias AlertProcessor.Repo

  def index(conn, _params, user, _claims) do
    case Subscription.for_user(user) do
      [] ->
        redirect(conn, to: subscription_path(conn, :new))
      subscriptions ->
        {:ok, departure_time_map} = DisplayInfo.departure_times_for_subscriptions(subscriptions)

        render conn, "index.html",
          subscriptions: subscriptions,
          departure_time_map: departure_time_map,
          vacation_start: user.vacation_start,
          vacation_end: user.vacation_end
    end
  end

  def new(conn, _params, user, _claims) do
    {amenity_name, amenity_url} = if amenity_sub = Subscription.user_amenity(user) do
      {"Edit Station Amenities (elevators & escalators)", amenity_subscription_path(conn, :edit, amenity_sub)}
    else
      {"Station Amenities (elevators & escalators)", amenity_subscription_path(conn, :new)}
    end
    render conn, amenity_url: amenity_url, amenity_name: amenity_name
  end

  def edit(conn, _params, _user, _claims) do
    render conn, "edit.html"
  end

  def confirm_delete(conn, %{"id" => id}, user, _claims) do
    subscription =
      id
      |> Subscription.one_for_user!(user.id)
      |> Repo.preload(:informed_entities)
    render conn, "confirm_delete.html", subscription: subscription
  end

  def delete(conn, %{"id" => id}, user, {:ok, claims}) do
    subscription = Subscription.one_for_user!(id, user.id)
    case Subscription.delete_subscription(subscription, Map.get(claims, "imp", user.id)) do
      {:ok, _} ->
        :ok = User.clear_holding_queue_for_user_id(user.id)
        conn
        |> put_flash(:info, "Subscription deleted")
        |> redirect(to: subscription_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, "Subscription could not be deleted. Please try again.")
        |> render("confirm_delete.html", subscription: subscription)
    end
  end
end
