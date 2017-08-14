defmodule ConciergeSite.Admin.SubscriberController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.{User, Notification}
  alias AlertProcessor.Repo
  alias ConciergeSite.AdminUserPolicy
  alias ConciergeSite.Dissemination.{Email, Mailer}

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

  def new_test_message(conn, %{"subscriber_id" => id}, user, _claims) do
    if AdminUserPolicy.can?(user, :send_targeted_message) do
      message_recipient = Repo.get(User, id)
      render conn, "target_message.html",
                    message_recipient: message_recipient
    else
      handle_unauthorized(conn)
    end
  end

  def send_notification(conn, %{"subscriber_id" => id, "targeted_message" => message_params}, user, _claims) do
    if AdminUserPolicy.can?(user, :send_targeted_message) do
      Email.targeted_notification_email(message_params)
      |> Mailer.deliver_later

      redirect(conn, to: admin_subscriber_path(conn, :index))
    else
      handle_unauthorized(conn)
    end
  end

  defp handle_unauthorized(conn) do
    conn
    |> put_status(403)
    |> render(ConciergeSite.ErrorView, "403.html")
  end
end
