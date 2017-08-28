defmodule ConciergeSite.Admin.SubscriberController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.{Subscription, User}
  alias AlertProcessor.Subscription.DisplayInfo
  alias ConciergeSite.{TargetedNotification, SubscriberDetails}

  def index(conn, params, _user, _claims) do
    page = Map.get(params, "page", 1)
    subscriber_page =
      case params["search"] do
        nil -> User.ordered_by_email(page)
        "" -> User.ordered_by_email(page)
        search_term -> User.search_by_contact_info(search_term, page)
      end

    render conn, "index.html", subscriber_page: subscriber_page, search_term: params["search"]
  end

  def show(conn, %{"id" => subscriber_id}, user, _claims) do
    subscriber = User.find_by_id(subscriber_id)
    notifications = SubscriberDetails.notification_timeline(subscriber)
    subscriptions = Subscription.for_user(subscriber)
    account_changelog = SubscriberDetails.changelog(subscriber_id)
    {:ok, departure_time_map} = DisplayInfo.departure_times_for_subscriptions(subscriptions)
    User.log_admin_action(:view_subscriber, user, subscriber)
    render conn, "show.html",
      subscriber: subscriber,
      subscriptions: subscriptions,
      departure_time_map: departure_time_map,
      account_changelog: account_changelog,
      notifications: notifications
  end

  def new_message(conn, %{"subscriber_id" => subscriber_id}, _user, _claims) do
    subscriber = User.find_by_id(subscriber_id)
    render conn, "target_message.html", subscriber: subscriber
  end

  def send_message(conn, %{"subscriber_id" => subscriber_id, "targeted_message" => message_params}, user, _claims) do
    subscriber = User.find_by_id(subscriber_id)
    User.log_admin_action(:message_subscriber, user, subscriber)
    TargetedNotification.send_targeted_notification(subscriber, message_params)

    redirect(conn, to: admin_subscriber_path(conn, :show, subscriber_id))
  end
end
