defmodule ConciergeSite.Admin.SubscriberController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.TargetedNotification

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

  def show(conn, %{"id" => subscriber_id}, _user, _claims) do
    subscriber = User.find_by_id(subscriber_id)

    render conn, "show.html", subscriber: subscriber
  end

  def new_message(conn, %{"subscriber_id" => subscriber_id}, _user, _claims) do
    subscriber = User.find_by_id(subscriber_id)
    render conn, "target_message.html", subscriber: subscriber
  end

  def send_message(conn, %{"subscriber_id" => subscriber_id, "targeted_message" => message_params}, _user, _claims) do
    subscriber_id
    |> User.find_by_id()
    |> TargetedNotification.send_targeted_notification(message_params)

    redirect(conn, to: admin_subscriber_path(conn, :show, subscriber_id))
  end
end
